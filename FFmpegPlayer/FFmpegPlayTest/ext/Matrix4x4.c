/*
 Matrix4x4.h/.c - matrix and vector math helpers
 */
#include "Matrix4x4.h"
#include <math.h>

void * memcpy(void*,const void*, int);

void matSetPerspective(Matrix4x4* m, float l, float r, float n, float f, float b, float t)
{
    
    m->m[0] = 2.f*n/(r-l);
    m->m[1] = 0;
    m->m[2] = 0;
    m->m[3] = 0;
    
    m->m[4] = 0;
    m->m[5] = 2.f*n/(t-b);
    m->m[6] = 0;
    m->m[7] = 0;
    
    m->m[8] = 0;
    m->m[9] = 0;
    m->m[10] = (n+f)/(f-n);
    m->m[11] = (-2.f) * f * n / (f-n);
    
    m->m[12] = 0;
    m->m[13] = 0;
    m->m[14] = 0;
    m->m[15] = 1;
}
void matSetOrtho(Matrix4x4* m, float left, float right, float bottom, float top, float near, float far)
{
	const float tx = - (right + left)/(right - left);
	const float ty = - (top + bottom)/(top - bottom);
	const float tz = - (far + near)/(far - near);

	m->m[0] = 2.0f/(right-left);
	m->m[1] = 0;
	m->m[2] = 0;
	m->m[3] = tx;
	
	m->m[4] = 0;
	m->m[5] = 2.0f/(top-bottom);
	m->m[6] = 0;
	m->m[7] = ty;
	
	m->m[8] = 0;
	m->m[9] = 0;
	m->m[10] = -2.0/(far-near);
	m->m[11] = tz;
	
	m->m[12] = 0;
	m->m[13] = 0;
	m->m[14] = 0;
	m->m[15] = 1;
}


void matSetRotY(Matrix4x4* m, float angle)
{
	const float c = cosf(angle);
	const float s = sinf(angle);

	m->m[0] = c;
	m->m[1] = 0;
	m->m[2] = -s;
	m->m[3] = 0;

	m->m[4] = 0;
	m->m[5] = 1;
	m->m[6] = 0;
	m->m[7] = 0;

	m->m[8] = s;
	m->m[9] = 0;
	m->m[10] = c;
	m->m[11] = 0;
	
	m->m[12] = 0;
	m->m[13] = 0;
	m->m[14] = 0;
	m->m[15] = 1;	
}


void matSetRotZ(Matrix4x4* m, float angle)
{
	const float c = cosf(angle);
	const float s = sinf(angle);

	m->m[0] = c;
	m->m[1] = -s;
	m->m[2] = 0;
	m->m[3] = 0;

	m->m[4] = s;
	m->m[5] = c;
	m->m[6] = 0;
	m->m[7] = 0;

	m->m[8] = 0;
	m->m[9] = 0;
	m->m[10] = 1;
	m->m[11] = 0;
	
	m->m[12] = 0;
	m->m[13] = 0;
	m->m[14] = 0;
	m->m[15] = 1;	
}


void matMul(Matrix4x4* m, const Matrix4x4* a, const Matrix4x4* b)
{
	m->m[0] = a->m[0]*b->m[0] + a->m[1]*b->m[4] + a->m[2]*b->m[8] + a->m[3]*b->m[12];
	m->m[1] = a->m[0]*b->m[1] + a->m[1]*b->m[5] + a->m[2]*b->m[9] + a->m[3]*b->m[13];
	m->m[2] = a->m[0]*b->m[2] + a->m[1]*b->m[6] + a->m[2]*b->m[10] + a->m[3]*b->m[14];
	m->m[3] = a->m[0]*b->m[3] + a->m[1]*b->m[7] + a->m[2]*b->m[11] + a->m[3]*b->m[15];

	m->m[4] = a->m[4]*b->m[0] + a->m[5]*b->m[4] + a->m[6]*b->m[8] + a->m[7]*b->m[12];
	m->m[5] = a->m[4]*b->m[1] + a->m[5]*b->m[5] + a->m[6]*b->m[9] + a->m[7]*b->m[13];
	m->m[6] = a->m[4]*b->m[2] + a->m[5]*b->m[6] + a->m[6]*b->m[10] + a->m[7]*b->m[14];
	m->m[7] = a->m[4]*b->m[3] + a->m[5]*b->m[7] + a->m[6]*b->m[11] + a->m[7]*b->m[15];

	m->m[8] = a->m[8]*b->m[0] + a->m[9]*b->m[4] + a->m[10]*b->m[8] + a->m[11]*b->m[12];
	m->m[9] = a->m[8]*b->m[1] + a->m[9]*b->m[5] + a->m[10]*b->m[9] + a->m[11]*b->m[13];
	m->m[10] = a->m[8]*b->m[2] + a->m[9]*b->m[6] + a->m[10]*b->m[10] + a->m[11]*b->m[14];
	m->m[11] = a->m[8]*b->m[3] + a->m[9]*b->m[7] + a->m[10]*b->m[11] + a->m[11]*b->m[15];

	m->m[12] = a->m[12]*b->m[0] + a->m[13]*b->m[4] + a->m[14]*b->m[8] + a->m[15]*b->m[12];
	m->m[13] = a->m[12]*b->m[1] + a->m[13]*b->m[5] + a->m[14]*b->m[9] + a->m[15]*b->m[13];
	m->m[14] = a->m[12]*b->m[2] + a->m[13]*b->m[6] + a->m[14]*b->m[10] + a->m[15]*b->m[14];
	m->m[15] = a->m[12]*b->m[3] + a->m[13]*b->m[7] + a->m[14]*b->m[11] + a->m[15]*b->m[15];
}
void vecMatTranslate(Matrix4x4 *mat,vec3 v)
{
	mat->m[12]=mat->m[0]*v.x+mat->m[4]*v.y+mat->m[8]*v.z+mat->m[12];
	mat->m[13]=mat->m[1]*v.x+mat->m[5]*v.y+mat->m[9]*v.z+mat->m[13];
	mat->m[14]=mat->m[2]*v.x+mat->m[6]*v.y+mat->m[10]*v.z+mat->m[14];
	mat->m[15]=mat->m[3]*v.x+mat->m[7]*v.y+mat->m[11]*v.z+mat->m[15];
}
vec3 vecNormalize(vec3 vec) {
    float vlen = 1.f / sqrtf(vec.x*vec.x + vec.y*vec.y + vec.z*vec.z);
    vec.x *= vlen;
    vec.y *= vlen;
    vec.z *= vlen;
    
    return vec;
    
}
vec3 vecCross(vec3 a, vec3 b){
    vec3 v;
    v.x = a.y*b.z - a.z*b.y;
    v.y = a.x*b.z - a.z*b.x;
    v.z = a.x*b.y - a.y*b.x;
    return v;
}
float vecDot(vec3 a, vec3 b) {
    float d;
    
    d = a.x * b.x + a.y * b.y + a.z * b.z;
    return d;
}
vec3 vecMul(vec3 a, float b) {
    vec3 v;
    v.x = a.x * b;
    v.y = a.y * b;
    v.z = a.z * b;
    return v;
}

vec3 vecSub(vec3 a, vec3 b){
    vec3 v;
    v.x = a.x - b.x;
    v.y = a.y - b.y;
    v.z = a.z - b.z;
    return v;
}

void matLookAt(Matrix4x4 *m, vec3 camera, vec3 point, vec3 vecNorm){
    vec3 forward, side, up;
    Matrix4x4 mat, mat2;
    
    memcpy(&mat2, m, sizeof(Matrix4x4));
    
    forward.x = point.x - camera.x;
    forward.y = point.y - camera.y;
    forward.z = point.z - camera.z;
    
    
    forward = vecNormalize(forward);
    
    up = vecNorm;
    
    
    side = vecCross(up, forward);
    up = vecCross(forward, side);
    
    side = vecNormalize(side);
    up = vecNormalize(up);

    // stolen from gluLookat.c
#define M(row,col) mat.m[col*4+row]
    M(0,0) = side.x;
    M(0,1) = side.y;
    M(0,2) = side.z;
    M(0,3) = 0.f;
    
    M(1,0) = up.x;
    M(1,1) = up.y;
    M(1,2) = up.z;
    M(1,3) = 0.f;
    
    M(2,0) = -forward.x;
    M(2,1) = -forward.y;
    M(2,2) = -forward.z;
    M(2,3) = 0.f;
    
    M(3,0) = M(3,1) = M(3,2) = 0.f;
    M(3,3) = 1.f;
#undef M
    // -----------------------
    
    matMul(m, &mat, &mat2);
    vecMatTranslate(m, camera);
}
