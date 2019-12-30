Shader "Unlit/Matrix"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        iChannel0("iChannel0", 2D) = "white" {}
        _Speed ("Speed", Float) = 1.0
        _Color1 ("Color1", Color) = (0.5, 0.5, 0.5, 1)
        _Color2 ("Color2", Color) = (0.67, 0.85, 0.8, 1)
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
            float _Speed;
            float4  _Color1;
            float4  _Color2;
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

            // Author @patriciogv - 2015
            // http://patriciogonzalezvivo.com

            float random(in float x){
                return fract(sin(x)*43758.5453);
            }

            float random(in vec2 st){
                return fract(sin(dot(st.xy ,vec2(12.9898,78.233))) * 43758.5453);
            }

            float randomChar(in vec2 outer,in vec2 inner){
                float grid = 5.;
                vec2 margin = vec2(.2,.05);
                float seed = 23.;
                vec2 borders = step(margin,inner)*step(margin,1.-inner);
                return step(.5,random(outer*seed+floor(inner*grid))) * borders.x * borders.y;
            }

            vec3 smatrix(in vec2 st){
                float rows = 50.0;
                vec2 ipos = floor(st*rows)+vec2(1.,0.);

                ipos += vec2(.0,floor(iTime*20.*random(ipos.x)));

                vec2 fpos = fract(st*rows);
                vec2 center = (.5-fpos);

                float pct = random(ipos);
                float glow = (1.-dot(center,center)*3.)*2.0;

                return svec3(randomChar(ipos,fpos) * pct * glow);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                //step5. fract 改 frac
                //step6. mat2 矩陣 改為 fixed2x2
                //step7. 矩陣運算 a*b 須改為 mul(a,b)  , 通常發生此問題的編譯錯誤都是 "type mismatch"
                //int2 轉換為 float2  ->  (float2)int2
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv; uv = 2.0 * uv - 1.0;
                fixed4 fragColor;
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                vec2 st = fragCoord.xy / iResolution.xy;
                st.y *= iResolution.y/iResolution.x;

                fragColor = vec4(smatrix(st),1.0);

                return fragColor;
            }
            ENDCG
        }
    }
}
