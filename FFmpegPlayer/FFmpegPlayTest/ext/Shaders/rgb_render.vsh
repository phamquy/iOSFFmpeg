//
//  Shader.vsh
//  Video_Player Demo
//
//  Created by James Hurley on 10-09-02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


attribute vec4 position;
attribute vec2 texCoords;
uniform mat4 viewProjectionMatrix;

varying  vec4 colorVarying;
varying vec2 _texcoord;

void main()
{
   
    _texcoord = texCoords;
   
    gl_Position = viewProjectionMatrix * position;

}
