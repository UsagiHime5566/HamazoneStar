Shader "Unlit/Some bubbles with weird colors."
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
            #define texture2D tex2D

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            
            #define ANTI_ALIASING

            vec3 circle( vec2 uv, vec2 pos, float radius, vec3 col ) {
                
                /*if( //sqrt(pow(uv.x-pos.x, 2.) + pow(uv.y-pos.y, 2.))
                length(uv-pos)
                <= radius) {
                    
                    return col;
                    
                }*/
                // @FabriceNeyret
                
                #ifdef ANTI_ALIASING
                    return smoothstep( 4./400., 0., length(uv-pos) - radius) * col;
                #else
                    return step( length(uv-pos), radius) * col;
                #endif
                
            }

            vec3 rBubble( vec2 uv, vec2 pos, float radius, vec3 col, float sw, float sws) {
                
                return circle(uv, vec2(pos.x+sin(iTime*2.*sws)/16.*sw, iTime/(radius*6.)), radius, col);
                
            }

            vec3 tBubble( vec2 uv, vec2 pos, float radius, vec3 col, vec2 sw, vec2 sws ) {
                
                return circle(uv,vec2(pos.x+sin(iTime/2.*sws.x)/16.*sw.x,pos.y+cos(iTime/2.)/16.*sw.y), radius, col);
                
            }

            vec3 tBubbleScatter( vec2 uv, float nB ) {
                
                vec3 circles = svec3(0.);
                
                for(float i = 0.; i < nB; i++) {
                    
                    circles += tBubble(uv, 
                    vec2(i/nB - nB/i + 1., tan(i-iTime) * nB/i - i/nB - 0.5), sin(i*2.+6.)/3., 
                    svec3(sin(i)+0.7),
                    vec2(tan(i/2.)*3., tan(i/5.)*2.), 
                    vec2( sin(i), cos(i) ) );
                    
                }
                
                return circles;
                
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
                fixed2 uv = i.uv; uv = 2.0 * uv - 1.0;

                fixed4 fragColor = svec4(1.);
                
                vec3 circles = rBubble( uv, vec2(0.1, 0.1), 0.4, vec3(0., 0.6, 0.6), 2., 1.);
                circles += tBubble( uv, vec2(0.3, 0.2), 0.3, vec3(0.5, 0.1, 0.2), vec2(8., 1.), vec2(3., 5.));
                
                vec3 circles2 = tBubbleScatter( uv, 200. );
                
                vec3 cbg = vec3(uv+sin(iTime), 1);
                vec3 cbg2 = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
                
                if(any(circles2 - svec3(0.))) {
                    fragColor = vec4(smoothstep(circles2, smoothstep(cbg2, cbg2, svec3(0.5)), svec3(0.7)), 1.);
                    } else {
                    if(uv.y <= -0.8+sin(uv.x+iTime+cos(iTime)+1.)/10.*cos(iTime)) {
                        fragColor = vec4(cbg2, 1.);
                        } else if(uv.y <= -0.6+sin(uv.x+iTime+cos(iTime)+1.)/15.*cos(iTime)){
                        fragColor = vec4(cbg2+svec3(0.4), 1.);
                    } else fragColor = svec4(1.);
                }

                return fragColor;
            }
            ENDCG
        }
    }
}
