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

  // Optional for point primitives
  float pointSize [[point_size]];
};

struct FragmentOut {
  float4 color0 [[color(0)]];
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
  float4x4 inverseModelMatrix;
};

vertex VertexOut basic_vertex(
  const VertexIn vIn [[ stage_in ]],
  const device Uniforms& uniforms [[ buffer(0) ]],
  const device ModelConstants& constants [[ buffer(1) ]]) {

  VertexOut vOut;
  vOut.position = uniforms.viewProjection * constants.modelMatrix * float4(vIn.position, 1.0);
  vOut.color = vIn.color;
  vOut.tex = vIn.tex;
  vOut.pointSize = 30.0;
  return vOut;
}

fragment FragmentOut color_fragment(VertexOut interpolated [[stage_in]],
                              float2 pointCoord [[point_coord]]) {
  //float dist = length(pointCoord - float2(0.5));

  FragmentOut out;
  //if (dist > 0.5) {
  //  out.color0 = float4(1.0, 0.0, 0.0, 1.0);
  //} else {
    out.color0 = interpolated.color;
  //}
  return out;
}

fragment FragmentOut texture_fragment(
  VertexOut interpolated [[stage_in]],
  texture2d<float, access::sample> diffuseTexture [[texture(0)]],
  sampler diffuseSampler [[sampler(0)]]) {

  FragmentOut out;
  out.color0 = diffuseTexture.sample(diffuseSampler, interpolated.tex).rgba;
  return out;
}


// For use with rendering ARKit video

typedef struct {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
} ImageVertex;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ImageColorInOut;

// Captured image vertex function
vertex ImageColorInOut capturedImageVertexTransform(ImageVertex in [[stage_in]]) {
    ImageColorInOut out;

    // Pass through the image vertex's position
    out.position = float4(in.position, 0.0, 1.0);

    // Pass through the texture coordinate
    out.texCoord = in.texCoord;

    return out;
}

// Captured image fragment function
fragment float4 capturedImageFragmentShader(ImageColorInOut in [[stage_in]],
                                            texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]]) {

    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );

    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.texCoord).r,
                          capturedImageTextureCbCr.sample(colorSampler, in.texCoord).rg, 1.0);

    // Return converted RGB color
  return ycbcrToRGBTransform * ycbcr;
}
