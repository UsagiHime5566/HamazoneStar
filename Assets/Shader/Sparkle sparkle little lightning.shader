Shader "Unlit/Sparkle sparkle little lightning"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        iChannel0("iChannel0", 2D) = "white" {}  
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D iChannel0;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            #define ivec2 int2
            #define ivec3 int3
            #define ivec4 int4
            #define vec2 float2
            #define vec3 float3
            #define vec4 float4
            #define svec2(x) float2(x,x)
            #define svec3(x) float3(x,x,x)
            #define svec4(x) float4(x,x,x,x)

            #define mat2 float2x2
            #define mat3 float3x3
            #define mat4 float4x4
            #define iTime _Time.y
            // fmod用于求余数，比如fmod(1.5, 1.0) 返回0.5；
            #define mod fmod
            // 插值运算，lerp(a,b,w) return a + w*(a-b);
            #define mix lerp
            // fract(x): 取小数部分 
            #define fract frac
            #define atan atan2
            #define texture2D tex2D

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            ////////////////////////////////////////////////////////////////////////////////
            //
            // Playing around with simplex noise and polar-coords with a lightning-themed
            // scene.
            //
            // Copyright 2019 Mirco Müller
            //
            // Author(s):
            //   Mirco "MacSlow" Müller <macslow@gmail.com>
            //
            // This program is free software: you can redistribute it and/or modify it
            // under the terms of the GNU General Public License version 3, as published
            // by the Free Software Foundation.
            //
            // This program is distributed in the hope that it will be useful, but
            // WITHOUT ANY WARRANTY; without even the implied warranties of
            // MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
            // PURPOSE.  See the GNU General Public License for more details.
            //
            // You should have received a copy of the GNU General Public License along
            // with this program.  If not, see <http://www.gnu.org/licenses/>.
            //
            ////////////////////////////////////////////////////////////////////////////////

            mat2 r2d (in float degree)
            {
                float rad = radians (degree);
                float c = cos (rad);
                float s = sin (rad);
                return mat2 (vec2 (c, s),vec2 (-s, c));
            }

            // using a slightly adapted implementation of iq's simplex noise from
            // https://www.shadertoy.com/view/Msf3WH with hash(), noise() and fbm()
            vec2 hash (in vec2 p)
            {
                p = vec2 (dot (p, vec2 (127.1, 311.7)),
                dot (p, vec2 (269.5, 183.3)));

                return -1. + 2.*fract (sin (p)*43758.5453123);
            }

            float noise (in vec2 p)
            {
                const float K1 = .366025404;
                const float K2 = .211324865;

                vec2 i = floor (p + (p.x + p.y)*K1);
                
                vec2 a = p - i + (i.x + i.y)*K2;
                vec2 o = step (a.yx, a.xy);    
                vec2 b = a - o + K2;
                vec2 c = a - 1. + 2.*K2;

                vec3 h = max (.5 - vec3 (dot (a, a), dot (b, b), dot (c, c) ), .0);

                vec3 n = h*h*h*h*vec3 (dot (a, hash (i + .0)),
                dot (b, hash (i + o)),
                dot (c, hash (i + 1.)));

                return dot (n, svec3 (70.));
            }

            float fbm (in vec2 p)
            {
                mat2 rot = r2d (27.5);
                float d = noise (p); p = mul(p,rot);
                d += .5*noise (p); p = mul(p,rot);
                d += .25*noise (p); p = mul(p,rot);
                d += .125*noise (p); p = mul(p,rot);
                d += .0625*noise (p);
                d /= (1. + .5 + .25 + .125 + .0625);
                return .5 + .5*d;
            }

            vec2 mapToScreen (in vec2 p, in float scale)
            {
                fixed2 iResolution = fixed2(400, 400);
                vec2 res = p;
                res = res * 2. - 1.;
                res.x *= iResolution.x / iResolution.y;
                res *= scale;
                
                return res;
            }

            vec2 cart2polar (in vec2 cart)
            {
                float r = length (cart);
                float phi = atan (cart.y, cart.x);
                return vec2 (r, phi); 
            }

            vec2 polar2cart (in vec2 polar)
            {
                float x = polar.x*cos (polar.y);
                float y = polar.x*sin (polar.y);
                return vec2 (x, y); 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                //step5. fract 改 frac
                //step6. mat2 矩陣 改為 fixed2x2
                //step7. 矩陣運算 a*b 須改為 mul(a,b)
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                //fixed2 uv = i.uv; uv = 2.0 * uv - 1.0;
                fixed4 fragColor;
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                vec2 uv = mapToScreen (fragCoord.xy/iResolution.xy, 2.5);

                uv = mul(uv,r2d (12.*iTime));
                float len = length (uv);
                float thickness = .25;
                float haze = 2.5;

                // distort UVs a bit
                uv = cart2polar (uv);
                uv.y += .2*(.5 + .5*sin(cos (uv.x)*len));
                uv = polar2cart (uv);

                float d1 = abs ((uv.x*haze)*thickness / (uv.x + fbm (uv + 1.25*iTime)));
                float d2 = abs ((uv.y*haze)*thickness / (uv.y + fbm (uv - 1.5*iTime)));
                float d3 = abs ((uv.x*uv.y*haze)*thickness / (uv.x*uv.y + fbm (uv - 2.*iTime)));
                vec3 col = svec3 (.0);
                float size = .075;
                col += d1*size*vec3 (.1, .8, 2.);
                col += d2*size*vec3 (2., .1, .8);
                col += d3*size*vec3 (.8, 2., .1);

                fragColor = vec4 (col, 1.);

                return fragColor;
            }
            ENDCG
        }
    }
}
