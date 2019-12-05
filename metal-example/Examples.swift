import Foundation
import simd
import MetalKit
import Toy3D
import UIKit

final class Examples {
  private let renderer: Renderer

  init(renderer: Renderer) {
    self.renderer = renderer
  }

  func createSceneSingleCube(textured: Bool) {
    renderer.scene.root.clearAllChildren()

    let dimension: Float = 3.0

    // Define the 3D vertices and colors for the vertices
    guard let cubeMesh = Primitives.cuboid(
      renderer: renderer,
      width: dimension,
      height: dimension,
      length: dimension,
      topColor: UIColor.red.cgColor,
      rightColor: UIColor.green.cgColor,
      bottomColor: UIColor.orange.cgColor,
      leftColor: UIColor.blue.cgColor,
      frontColor: UIColor.yellow.cgColor,
      backColor: UIColor.purple.cgColor
    ) else {
      print("Failed to create the cuboid mesh")
      return
    }

    var texture: Texture?
    if textured {
      guard let metalTexture = Texture.loadMetalTexture(device: renderer.device, named: "bricks") else {
        return
      }

      let samplerDescriptor = MTLSamplerDescriptor()
      samplerDescriptor.normalizedCoordinates = true
      samplerDescriptor.minFilter = .linear
      samplerDescriptor.magFilter = .linear
      samplerDescriptor.mipFilter = .linear
      guard let sampler = renderer.device.makeSamplerState(descriptor: samplerDescriptor) else {
        return
      }

      texture = Texture(mtlTexture: metalTexture, samplerState: sampler)
    }

    let material = Material.createBasic(renderer: renderer, texture: texture)


    cubeMesh.material = material
    let node = Node(mesh: cubeMesh)
    node.update = { (time: Time, node: Node) in
      node.orientation *= Quaternion(
        angle: Math.toRadians(30.0) * Float(time.updateTime),
        axis: [0.5, 1, -1]
      )
    }
    renderer.scene.root.addChild(node)
  }

  func createSceneMultipleCubes(cubeDimension: Float, cubeCount: Int) {
    renderer.scene.root.clearAllChildren()

    let scene = renderer.scene
    let dimension: Float = 3.0

    // Reuse the same mesh across all cubes
    guard let cubeMesh = Primitives.cuboid(
      renderer: renderer,
      width: cubeDimension,
      height: cubeDimension,
      length: cubeDimension,
      topColor: UIColor.red.cgColor,
      rightColor: UIColor.green.cgColor,
      bottomColor: UIColor.orange.cgColor,
      leftColor: UIColor.blue.cgColor,
      frontColor: UIColor.yellow.cgColor,
      backColor: UIColor.purple.cgColor
    ) else {
      print("Failed to create the cuboid mesh")
      return
    }

    let material = Material.createBasic(renderer: renderer, texture: nil)
    cubeMesh.material = material

    let containerNode = Node()
    containerNode.update = { (time: Time, node: Node) in
      node.orientation *= Quaternion(angle: Math.toRadians(30.0) * Float(time.updateTime), axis: [0.5, 1, -1])
    }
    scene.root.addChild(containerNode)
    containerNode.orientation = Quaternion(angle: Math.toRadians(45.0), axis: [0, 1, 0])

    for _ in 0..<cubeCount {
      let cubeNode = Node(mesh: cubeMesh)
      cubeNode.position = [
        Float.random(in: -dimension...dimension),
        Float.random(in: -dimension...dimension),
        Float.random(in: -dimension...dimension)
      ]
      cubeNode.scale = [0.1, 0.1, 0.1]

      cubeNode.update = { (time: Time, node: Node) in
        node.orientation *= Quaternion(angle: Math.toRadians(30.0) * Float(time.updateTime), axis: [0.5, 1, -1])
      }
      containerNode.addChild(cubeNode)
    }
  }

  func createSceneBunny() {
    // Stanford Bunny data from: https://casual-effects.com/data/

    renderer.scene.root.clearAllChildren()

    guard let url = Bundle.main.url(forResource: "bunny", withExtension: "obj") else {
      return
    }

    let bufferIndex = Renderer.firstFreeVertexBufferIndex

    // position
    let vertexDescriptor = MDLVertexDescriptor()
    vertexDescriptor.attributes[0] = MDLVertexAttribute(
      name: MDLVertexAttributePosition,
      format: .float3,
      offset: 0,
      bufferIndex: bufferIndex
    )

    // normal
    vertexDescriptor.attributes[1] = MDLVertexAttribute(
      name: MDLVertexAttributeNormal,
      format: .float3,
      offset: MemoryLayout<Float>.size * 3,
      bufferIndex: bufferIndex
    )

    // color
    vertexDescriptor.attributes[2] = MDLVertexAttribute(
      name: MDLVertexAttributeColor,
      format: .float4,
      offset: MemoryLayout<Float>.size * 6,
      bufferIndex: bufferIndex
    )

    // texture coords
    vertexDescriptor.attributes[3] = MDLVertexAttribute(
      name: MDLVertexAttributeTextureCoordinate,
      format: .float2,
      offset: MemoryLayout<Float>.size * 10,
      bufferIndex: bufferIndex
    )
    vertexDescriptor.layouts[bufferIndex] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 12)

    let metalVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)!

    let allocator = MTKMeshBufferAllocator(device: renderer.device)
    let asset = MDLAsset(url: url, vertexDescriptor: vertexDescriptor, bufferAllocator: allocator)

    var meshes = [MTKMesh]()
    do {
      (_, meshes) = try MTKMesh.newMeshes(asset: asset, device: renderer.device)
    } catch {
      print("Could not load meshes from model")
    }

    guard let bunnyMetalTexture = Texture.loadMetalTexture(device: renderer.device, named: "bricks") else {
      return
    }

    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.normalizedCoordinates = true
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.mipFilter = .linear
    guard let sampler = renderer.device.makeSamplerState(descriptor: samplerDescriptor) else {
      return
    }

    let bunnyTexture = Texture(mtlTexture: bunnyMetalTexture, samplerState: sampler)

    let bunnyMaterial = Material(
      renderer: renderer,
      vertexName: "basic_vertex",
      fragmentName: "texture_fragment",
      vertexDescriptor: metalVertexDescriptor,
      texture: bunnyTexture
    )

    let bunnyMesh = Mesh(mtkMesh: meshes[0])
    bunnyMesh.material = bunnyMaterial

    let bunnyNode = Node(mesh: bunnyMesh)
    bunnyNode.scale = [2.5, 2.5, 2.5]
    bunnyNode.position.y = -2
    bunnyNode.update = { (time: Time, node: Node) in
      node.orientation *= Quaternion(angle: Math.toRadians(60.0) * Float(time.updateTime), axis: [0, 1, 0])
    }
    renderer.scene.root.addChild(bunnyNode)
  }
}
