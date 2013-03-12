/*
 * anaglyph.fsh - Anaglyph (red/cyan) half-color stereoscopic filter. Get some red/cyan 3D glasses.
 * Using really naive scaling for the demo.
 * jamesghurley<at>gmail.com
 */
uniform sampler2D sampler0;
varying highp vec2 _texcoord;

void main()
{
    gl_FragColor = texture2D(sampler0, _texcoord);
}