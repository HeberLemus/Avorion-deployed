#include "version.inl"

in vec4 color;

uniform sampler2D permTexture;
uniform vec4 first;
uniform vec4 second;

void main()
{
    float dither = texture(permTexture, gl_FragCoord.xy / 256.0).a / 128.0;

    outFragColor = mix(first, second, clamp(color.r, 0, 1));
    outFragColor.rgb += vec3(dither);
}
