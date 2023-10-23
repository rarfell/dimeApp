#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// CHROMATIC ABERRATION (TIME)

// DESCRIPTION
// https://en.wikipedia.org/wiki/Chromatic_aberration

// LAYER EFFECT
// https://developer.apple.com/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:

[[ stitchable ]] half4 chromatic_abberation_time(float2 position, SwiftUI::Layer layer, float time, float strength) {

    // FIRST, WE STORE THE ORIGINAL COLOR.
    half4 original_color = layer.sample(position);
    
    // WE CREATE A NEW COLOR VARIABLE TO STORE THE MODIFIED COLOR.
    half4 new_color = original_color;
    
    // WE MANIPULATE THE STRENGTH OF THE EFFECT BASED ON THE SIN OF THE TIME
    strength = (1.0 + sin(time*6.0)) * 0.65;
    strength *= 1.0 + sin(time*16.0) * 0.65;
    strength *= 1.0 + sin(time*19.0) * 0.65;
    strength *= 1.0 + sin(time*27.0) * 0.65;
    strength = pow(strength, 3.0);
    strength *= 0.75;
    
    // WE SAMPLE THE LAYER AT DIFFERENT OFFSETS TO CREATE THE CHROMATIC ABERRATION EFFECT
    new_color.r = layer.sample(position + float2(strength/2.2, -strength/2)).r;
    new_color.g = layer.sample(position).g;
    new_color.b = layer.sample(position - float2(strength/2, -strength/2.1)).b;
    
    return new_color;
}
