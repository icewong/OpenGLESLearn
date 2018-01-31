//
//  Shader.vsh
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

attribute vec4 position;
attribute vec2 texCoord;

varying vec2 v_textureCoordinate;

uniform mat4 modelViewProjectionMatrix;

/////////////////////////
attribute vec4 Position;
attribute vec2 TextureCoords;


void main() {
    v_textureCoordinate = texCoord;
    gl_Position = modelViewProjectionMatrix * position;
    //用来展现纹理的多边形顶点
    //gl_Position = Position;
    //表示使用的纹理的范围的顶点，因为是2D纹理，所以用vec2类型
    //TextureCoordsOut = TextureCoords;
}
