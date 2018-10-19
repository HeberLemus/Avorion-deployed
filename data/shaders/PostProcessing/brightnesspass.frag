#include "../version.inl"

uniform sampler2D sourceTexture;
uniform float threshold;

in vec2 texCoord;

void main()
{
    vec4 texColor = texture(sourceTexture, vec2(texCoord.x, texCoord.y));
    vec4 color = max(vec4(0.0), texColor - threshold);

    float lightness = color.r * 0.3 + color.g * 0.59 + color.b * 0.11 + 0.001;
    float wantedLightness = min(0.4, lightness);
    color = color / lightness * wantedLightness;

    outFragColor = color;
}
