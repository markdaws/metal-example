import UIKit
import ModelIO
import MetalKit
import Toy3D

final class GameViewController: UIViewController {

  private enum Demo {
    case singleCube
    case singleCubeTextured
    case singleCubeVideo
    case multipleCubesFew
    case multipleCubesMany
    case bunny
  }

  @IBOutlet private weak var fpsLabel: UILabel!
  private var currentDemoType = Demo.singleCube
  private var renderer: Renderer!
  private var mtkView: MTKView!
  private var examples: Examples!

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let mtkView = view as? MTKView else {
      print("View of Gameview controller is not an MTKView")
      return
    }

    guard let renderer = Renderer(mtkView: mtkView) else {
      print("Renderer cannot be initialized")
      return
    }
    self.renderer = renderer

    let scale = UIScreen.main.scale

    self.renderer.onFrame = { [unowned renderer] in
      self.examples.onRendererFrame()
      
      let size = mtkView.bounds.size
      self.fpsLabel.text = "[\(size.width * scale) x \(size.height * scale)], FPS: \(String(format: "%.0f", renderer.fpsCounter.currentFPS))"
    }

    mtkView.delegate = renderer
    renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

    // Tap to change the demos
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
    tapGesture.numberOfTapsRequired = 1
    mtkView.addGestureRecognizer(tapGesture)

    // Class containing several different demo scenes
    examples = Examples(renderer: renderer)
    examples.createSceneSingleCube(textured: false)
  }

  @objc func onTap(_ recognizer: UITapGestureRecognizer) {
    switch currentDemoType {

    case .singleCube:
      examples.createSceneSingleCube(textured: true)
      currentDemoType = .singleCubeTextured

    case .singleCubeTextured:
      renderer.scene.camera.origin = [0, 0, 7]
      examples.createSceneVideoTextureCube()
      currentDemoType = .singleCubeVideo

    case .singleCubeVideo:
      renderer.scene.camera.origin = [0, 0, 7]
      examples.createSceneMultipleCubes(cubeDimension: 1.0, cubeCount: 100)
      currentDemoType = .multipleCubesFew

    case .multipleCubesFew:
      renderer.scene.camera.origin = [0, 0, 7]
      examples.createSceneMultipleCubes(cubeDimension: 0.5, cubeCount: 10000)
      currentDemoType = .multipleCubesMany

    case .multipleCubesMany:
      renderer.scene.camera.origin = [0, 0, 5]
      examples.createSceneBunny()
      currentDemoType = .bunny

    case .bunny:
      examples.createSceneSingleCube(textured: false)
      currentDemoType = .singleCube
    }
  }

}
