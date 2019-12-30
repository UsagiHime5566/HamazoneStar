Shader "Unlit/Bubble rings"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            
            // --------------------------------------------------------
            // HG_SDF
            // https://www.shadertoy.com/view/Xs3GRB
            // --------------------------------------------------------

            #define PI 3.14159265359

            void pR(inout fixed2 p, float a) {
                p = cos(a)*p + sin(a)*fixed2(p.y, -p.x);
            }

            float smax(float a, float b, float r) {
                fixed2 u = max(fixed2(r + a,r + b), _fixed2(0));
                return min(-r, max (a, b)) + length(u);
            }


            // --------------------------------------------------------
            // Spectrum colour palette
            // IQ https://www.shadertoy.com/view/ll2GD3
            // --------------------------------------------------------

            fixed3 pal( in float t, in fixed3 a, in fixed3 b, in fixed3 c, in fixed3 d ) {
                return a + b*cos( 6.28318*(c*t+d) );
            }

            fixed3 spectrum(float n) {
                return pal( n, fixed3(0.5,0.5,0.5),fixed3(0.5,0.5,0.5),fixed3(1.0,1.0,1.0),fixed3(0.0,0.33,0.67) );
            }


            // --------------------------------------------------------
            // Main SDF
            // https://www.shadertoy.com/view/wsfGDS
            // --------------------------------------------------------

            fixed4 inverseStereographic(fixed3 p, out float k) {
                k = 2.0/(1.0+dot(p,p));
                return fixed4(k*p,k-1.0);
            }

            float fTorus(fixed4 p4) {
                float d1 = length(p4.xy) / length(p4.zw) - 1.;
                float d2 = length(p4.zw) / length(p4.xy) - 1.;
                float d = d1 < 0. ? -d1 : d2;
                d /= PI;
                return d;
            }

            float fixDistance(float d, float k) {
                float sn = sign(d);
                d = abs(d);
                d = d / k * 1.82;
                d += 1.;
                d = pow(d, .5);
                d -= 1.;
                d *= 5./3.;
                d *= sn;
                return d;
            }

            float time;

            float map(fixed3 p) {
                float k;
                fixed4 p4 = inverseStereographic(p,k);

                pR(p4.zy, time * -PI / 2.);
                pR(p4.xw, time * -PI / 2.);

                // A thick walled clifford torus intersected with a sphere

                float d = fTorus(p4);
                d = abs(d);
                d -= .2;
                d = fixDistance(d, k);
                d = smax(d, length(p) - 1.85, .2);

                return d;
            }


            // --------------------------------------------------------
            // Rendering
            // --------------------------------------------------------

            fixed3x3 calcLookAtMatrix(fixed3 ro, fixed3 ta, fixed3 up) {
                fixed3 ww = normalize(ta - ro);
                fixed3 uu = normalize(cross(ww,up));
                fixed3 vv = normalize(cross(uu,ww));
                return fixed3x3(uu, vv, ww);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. fmod 改 ffmod  or  #define fmod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                //step5. fract 改 frac
                //step6. mat2 矩陣 改為 fixed2x2
                //step7. 矩陣運算 a*b 須改為 mul(a,b)
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv;
                uv = 2.0 * uv - 1.0;

                time = fmod(_Time.y / 2., 1.);

                fixed3 camPos = fixed3(1.8, 5.5, -5.5) * 1.75;
                fixed3 camTar = fixed3(.0,0,.0);
                fixed3 camUp = fixed3(-1,0,-1.5);
                fixed3x3 camMat = calcLookAtMatrix(camPos, camTar, camUp);
                float focalLength = 5.;
                //fixed2 p = (-iResolution.xy + 2. * gl_FragCoord.xy) / iResolution.y;
                fixed2 p = i.uv ;

                fixed3 rayDirection = normalize(mul(camMat , fixed3(p, focalLength)));
                fixed3 rayPosition = camPos;
                float rayLength = 0.;

                float distance = 0.;
                fixed3 color = _fixed3(0);

                fixed3 c;

                // Keep iteration count too low to pass through entire fmodel,
                // giving the effect of fogged glass
                const float ITER = 82.;
                const float FUDGE_FACTORR = .8;
                const float INTERSECTION_PRECISION = .001;
                const float MAX_DIST = 20.;

                for (float i = 0.; i < ITER; i++) {

                    // Step a little slower so we can accumilate glow
                    rayLength += max(INTERSECTION_PRECISION, abs(distance) * FUDGE_FACTORR);
                    rayPosition = camPos + rayDirection * rayLength;
                    distance = map(rayPosition);

                    // Add a lot of light when we're really close to the surface
                    c = _fixed3(max(0., .01 - abs(distance)) * .5);
                    c *= fixed3(1.4,2.1,1.7); // blue green tint

                    // Accumilate some purple glow for every step
                    c += fixed3(.6,.25,.7) * FUDGE_FACTORR / 160.;
                    c *= smoothstep(20., 7., length(rayPosition));

                    // Fade out further away from the camera
                    float rl = smoothstep(MAX_DIST, .1, rayLength);
                    c *= rl;

                    // Vary colour as we move through space
                    c *= spectrum(rl * 6. - .6);

                    color += c;

                    if (rayLength > MAX_DIST) {
                        break;
                    }
                }

                // Tonemapping and gamma
                color = pow(color, _fixed3(1. / 1.8)) * 2.;
                color = pow(color, _fixed3(2.)) * 3.;
                color = pow(color, _fixed3(1. / 2.2));

                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
