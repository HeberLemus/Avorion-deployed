#include "version.inl"

#ifdef NUM_INSTANCES
uniform mat4 mViewProjection;
uniform mat4 mWorld[NUM_INSTANCES];

uniform float uTimeAlive[NUM_INSTANCES];
uniform vec3 uColors[NUM_INSTANCES];

#else

uniform mat4 mWorldViewProjection;
uniform mat4 mWorld;

uniform float uTimeAlive;
uniform vec3 uColor;
#endif // NUM_INSTANCES

out vec3 position;
out vec3 normal;
out vec3 innerColor;
out vec2 texCoord;
out float timeAlive;

void main(void)
{
#ifdef NUM_INSTANCES
    int i = gl_InstanceID;

    gl_Position = mViewProjection * mWorld[i] * vec4(vPosition, 1.0);
    position = vec3(mWorld[i] * vec4(vPosition, 1.0));
    normal = vec3(mWorld[i] * vec4(vNormal, 0.0));
    timeAlive = uTimeAlive[i];

    innerColor = uColors[i];

#else

    gl_Position = mWorldViewProjection * vec4(vPosition, 1.0);

    position = vec3(mWorld * vec4(vPosition, 1.0));
    normal = vec3(mWorld * vec4(vNormal, 0.0));
    timeAlive = uTimeAlive;

    innerColor = uColor;
#endif // NUM_INSTANCES

//    texCoord = vTex;
    texCoord = vec2(vPosition.x, vPosition.z);
}
