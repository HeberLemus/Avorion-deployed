#include "version.inl"

uniform sampler2D shockwaveTexture;

in vec3 position;
in vec3 normal;
in vec3 innerColor;
in vec2 texCoord;
in float timeAlive;

void main()
{
    const float centerDist = 0.6;
    const vec3 outerColor = vec3(1.2, 0.3, 0.1);

    float dist = length(texCoord);
    float gradient = (dist - centerDist) / (1.0 - centerDist);

//    gradient = pow(gradient, 1.0 + timeAlive * 20.0);

    // soft outer edge
    float gradient2 = min(-20.0 * dist + 19.0, gradient);
    // fade out in the end
    gradient2 = min(-3.0 * timeAlive + 2.5, gradient2);

    float offset = gradient2 - 0.5;

    vec4 wave = texture(shockwaveTexture, texCoord * 0.5 + vec2(0.5));
    float v = clamp(wave.r + offset, 0.0, 1.0);

    vec3 color = mix(innerColor, outerColor, gradient * gradient * gradient);

    outFragColor.rgb = color * v;
    outFragColor.a = 1.0; // no alpha blending used

#if defined(DEFERRED)
    vec3 nnormal = normalize(normal);

    outNormalColor = vec4(nnormal, 0);
    outPositionColor = vec4(position, gl_FragCoord.z / gl_FragCoord.w);
#endif
}
