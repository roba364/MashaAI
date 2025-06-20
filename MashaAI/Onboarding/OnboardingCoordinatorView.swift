import AVFoundation
import AVKit
import SwiftUI
import UIKit

// MARK: - Video Player Manager для сохранения состояния
class VideoPlayerManager: ObservableObject {
  private var players: [String: VideoPlayerUIView] = [:]
  private let queue = DispatchQueue(label: "video.player.manager", attributes: .concurrent)

  func getOrCreatePlayer(for url: URL) -> VideoPlayerUIView {
    let key = url.absoluteString

    return queue.sync {
      if let existingPlayer = players[key] {
        return existingPlayer
      }

      let newPlayer = VideoPlayerUIView()
      newPlayer.configure(with: url)
      players[key] = newPlayer
      return newPlayer
    }
  }

  func pauseAllPlayers() {
    queue.async(flags: .barrier) {
      self.players.values.forEach { $0.pause() }
    }
  }

  func resumeAllPlayers() {
    queue.async(flags: .barrier) {
      self.players.values.forEach { $0.play() }
    }
  }

  func cleanup() {
    queue.async(flags: .barrier) {
      self.players.removeAll()
    }
  }
}

// MARK: - UIKit Video Player
final class VideoPlayerUIView: UIView {

  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var playerLooper: AVPlayerLooper?
  private var queuePlayer: AVQueuePlayer?

  // Snapshot механизм
  private var snapshotImageView: UIImageView?
  private var lastFrameSnapshot: UIImage?

  private var shouldAutoPlay = true
  private var videoURL: URL?
  private var isInBackground = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupNotifications()
    setupSnapshotImageView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupNotifications()
    setupSnapshotImageView()
  }

  deinit {
    //        cleanupPlayer()
    //        cleanupSnapshot()
    NotificationCenter.default.removeObserver(self)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer?.frame = bounds
    snapshotImageView?.frame = bounds
  }

  func configure(with url: URL) {
    // Не пересоздаём плеер если URL тот же самый
    guard self.videoURL != url else { return }

    self.videoURL = url
    setupPlayer(with: url)
  }

  private func setupSnapshotImageView() {
    snapshotImageView = UIImageView()
    snapshotImageView?.contentMode = .scaleAspectFill
    snapshotImageView?.clipsToBounds = true
    snapshotImageView?.isHidden = true
    snapshotImageView?.backgroundColor = .clear

    if let snapshotImageView = snapshotImageView {
      addSubview(snapshotImageView)
    }
  }

  private func setupPlayer(with url: URL) {
    cleanupPlayer()

    let playerItem = AVPlayerItem(url: url)
    queuePlayer = AVQueuePlayer(playerItem: playerItem)
    player = queuePlayer

    // Создаём зацикленное воспроизведение
    guard let queuePlayer = queuePlayer else { return }
    playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

    // Настраиваем слой для отображения видео
    playerLayer = AVPlayerLayer(player: player)
    playerLayer?.videoGravity = .resizeAspectFill
    playerLayer?.frame = bounds

    if let playerLayer = playerLayer {
      layer.addSublayer(playerLayer)
    }

    // Приводим snapshot view наверх
    if let snapshotImageView = snapshotImageView {
      bringSubviewToFront(snapshotImageView)
    }

    // Автоматически начинаем воспроизведение если нужно
    if shouldAutoPlay && !isInBackground {
      player?.play()
    }
  }

  private func setupNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
  }

  @objc private func applicationWillResignActive() {
    captureCurrentFrame()
    showSnapshot()
    player?.pause()
  }

  @objc private func applicationDidBecomeActive() {
    isInBackground = false
    if shouldAutoPlay {
      player?.play()
      // Даём небольшую задержку чтобы видео начало проигрываться
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
        self.hideSnapshot()
      }
    }
  }

  @objc private func applicationDidEnterBackground() {
    isInBackground = true
    captureCurrentFrame()
    showSnapshot()
    player?.pause()
  }

  @objc private func applicationWillEnterForeground() {
    isInBackground = false
    // Пересоздаём плеер если потерялся после backgrounding
    if player?.currentItem == nil, let videoURL = videoURL {
      setupPlayer(with: videoURL)
    }
  }

  // MARK: - Snapshot Methods

  private func captureCurrentFrame() {
    guard let player = player,
      let playerItem = player.currentItem,
      let asset = playerItem.asset as? AVURLAsset
    else { return }

    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceAfter = .zero
    imageGenerator.requestedTimeToleranceBefore = .zero

    let currentTime = player.currentTime()

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      do {
        let cgImage = try imageGenerator.copyCGImage(at: currentTime, actualTime: nil)
        let snapshot = UIImage(cgImage: cgImage)

        DispatchQueue.main.async {
          self?.lastFrameSnapshot = snapshot
        }
      } catch {
        print("Failed to capture frame: \(error)")
        // Fallback: используем последний сохранённый snapshot
      }
    }
  }

  private func showSnapshot() {
    guard let snapshot = lastFrameSnapshot else { return }

    DispatchQueue.main.async { [weak self] in
      self?.snapshotImageView?.image = snapshot
      self?.snapshotImageView?.isHidden = false
      self?.snapshotImageView?.alpha = 1.0
    }
  }

  private func hideSnapshot() {
    DispatchQueue.main.async { [weak self] in
      UIView.animate(
        withDuration: 0.2,
        animations: {
          self?.snapshotImageView?.alpha = 0.0
        },
        completion: { _ in
          self?.snapshotImageView?.isHidden = true
          self?.snapshotImageView?.image = nil
        }
      )
    }
  }

  private func cleanupSnapshot() {
    snapshotImageView?.removeFromSuperview()
    snapshotImageView = nil
    lastFrameSnapshot = nil
  }

  // MARK: - Public Methods

  func play() {
    shouldAutoPlay = true
    if !isInBackground {
      player?.play()
      hideSnapshot()
    }
  }

  func pause() {
    shouldAutoPlay = false
    captureCurrentFrame()
    showSnapshot()
    player?.pause()
  }

  private func cleanupPlayer() {
    playerLooper?.disableLooping()
    playerLooper = nil
    player?.pause()
    player = nil
    playerLayer?.removeFromSuperlayer()
    playerLayer = nil
    queuePlayer = nil
  }

  // Для финальной очистки когда плеер больше не нужен
  func finalCleanup() {
    cleanupPlayer()
    cleanupSnapshot()
  }
}

// MARK: - SwiftUI Wrapper
struct UIKitVideoPlayer: UIViewRepresentable {
  let videoURL: URL
  @EnvironmentObject private var playerManager: VideoPlayerManager

  func makeUIView(context: Context) -> VideoPlayerUIView {
    let player = playerManager.getOrCreatePlayer(for: videoURL)
    return player
  }

  func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
    // Обновляем видео если URL изменился
    uiView.configure(with: videoURL)
  }

  static func dismantleUIView(_ uiView: VideoPlayerUIView, coordinator: ()) {
    // При удалении view показываем снапшот, но НЕ удаляем плеер
    uiView.pause()
  }
}

// MARK: - Main Coordinator View
struct OnboardingCoordinatorView: View {

  @ObservedObject
  var coordinator: OnboardingCoordinator

  @StateObject private var playerManager = VideoPlayerManager()

  var body: some View {
    VStack(spacing: 20) {
      UIKitVideoPlayer(
        videoURL: Bundle.main.url(forResource: "paywall_background", withExtension: "mp4")!
      )
      .frame(width: 200, height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 12))

      UIKitVideoPlayer(
        videoURL: Bundle.main.url(forResource: "paywall_banner", withExtension: "mp4")!
      )
      .frame(width: 200, height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 12))

      UIKitVideoPlayer(
        videoURL: Bundle.main.url(forResource: "practice_banner", withExtension: "mp4")!
      )
      .frame(width: 200, height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .environmentObject(playerManager)
    .onDisappear {
      // Паузим все плееры когда view исчезает, но НЕ удаляем их
      playerManager.pauseAllPlayers()
    }
    .onAppear {
      // Возобновляем плееры когда view появляется
      playerManager.resumeAllPlayers()
    }
  }
}
