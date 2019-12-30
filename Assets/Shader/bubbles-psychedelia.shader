Shader "Unlit/bubbles-psychedelia"
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
                fixed2 uv = i.uv;// uv = 2.0 * uv - 1.0;
                fixed4 fragColor;

                //vec2 uv = U/iResolution.xy * vec2(4,2) + vec2(-2,1.1);
                float pi = 3.14,
                time = iTime * 0.1,
                t = time*pi,
                d = length(uv)-.3;
                
                uv = mul(uv,mat2( cos(t), -sin(t)*(d)*0.5, sin(t), cos(t)));
                
                
                float  timeWobble = cos(t+d)*.1*d,
                tt = fract(sin(t))*0.01,
                v = 0.;
                
                for(float j = 0.; j<24.; j+=.5){
                    float q = j==0.? tt+.25 : 1.;
                    for(float i = 0.; i<6.28; i+=pi/16.){
                        vec2 u = uv+vec2(sin(i), cos(i))*(j-timeWobble+tt-0.25)*q;
                        v += smoothstep(.00, .1*(sin(t)*(1.0-d)*time*0.1), 
                        length(u*2.0)-(smoothstep(0., 0.4,j+tt)+timeWobble*1.0)* q*2.);
                    }
                }
                fragColor = 0.5 + 0.5* cos(  pi * .5 * ( mod(v, 5. ) + sin(vec4(10,5,-10,0)*t) )  );
                return fragColor;
            }
            ENDCG
        }
    }
}
