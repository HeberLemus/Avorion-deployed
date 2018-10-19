#include "version.inl"

uniform mat4 mWorldViewProjection;
uniform vec4 uColor;

out vec4 color;

void main(void)
{
    gl_Position = mWorldViewProjection * vec4(vPosition, 1.0);
    color = vColor * uColor;
}

