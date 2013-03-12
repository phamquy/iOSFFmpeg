/*
    Matrix4x4.h/.c - matrix and vector math helpers
 */
#ifndef st_Matrix4x4_h_
#define st_Matrix4x4_h_

typedef struct 
{
	float m[16];
}Matrix4x4;

typedef struct {
    float x, y, z;
    
} vec3;


void matSetPerspective(Matrix4x4* m, float l, float r, float n, float f, float b, float t);
void matSetOrtho(Matrix4x4* m, float left, float right, float bottom, float top, float near, float far);
void matSetRotY(Matrix4x4* m, float angle);
void matSetRotZ(Matrix4x4* m, float angle);
void matMul(Matrix4x4* m, const Matrix4x4* a, const Matrix4x4* b);
void vecMatTranslate(Matrix4x4 *mat,vec3 v);

vec3 vecNormalize(vec3 vec);
vec3 vecCross(vec3 a, vec3 b);
vec3 vecMul(vec3 a, float b);
vec3 vecSub(vec3 a, vec3 b);

float vecDot(vec3 a, vec3 b);


void matLookAt(Matrix4x4 *m, vec3 camera, vec3 point, vec3 vecNorm);
#endif
