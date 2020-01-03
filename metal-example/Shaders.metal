// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct VertexIn {
  float3 position [[attribute(0)]];
  float3 normal [[attribute(1)]];
  float4 color [[attribute(2)]];
  float2 tex [[attribute(3)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 color;
  float2 tex;
};

struct Uniforms {
  float time;
  int2 resolution;
  float4x4 view;
  float4x4 inverseView;
  float4x4 viewProjection;
};

struct ModelConstants {
  float4x4 modelMatrix;
};

vertex VertexOut basic_vertex(
  const VertexIn vIn [[ stage_in ]],
  const device Uniforms& uniforms [[ buffer(0) ]],
  const device ModelConstants& constants [[ buffer(1) ]]) {

  VertexOut vOut;
  vOut.position = uniforms.viewProjection * constants.modelMatrix * float4(vIn.position, 1.0);
  vOut.color = vIn.color;
  vOut.tex = vIn.tex;
  return vOut;
}

fragment half4 color_fragment(VertexOut interpolated [[stage_in]]) {
  return half4(interpolated.color);
}

fragment float4 texture_fragment(
  VertexOut interpolated [[stage_in]],
  texture2d<float, access::sample> diffuseTexture [[texture(0)]],
  sampler diffuseSampler [[sampler(0)]]) {

  return diffuseTexture.sample(diffuseSampler, interpolated.tex).rgba;
}
