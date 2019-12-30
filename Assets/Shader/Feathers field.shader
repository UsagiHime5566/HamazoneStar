Shader "Unlit/Feathers field"
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
            #define texture2D tex2D

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            //#define col(i) vec4( vec3(C[i]), 1 )
            //#define col(i) vec4(   .6 + .6 * cos(l-iTime+float(i) +vec3(0,23,21) ), 1 )        // colored
            #define col(i) vec4( ( .6 + .6 * cos(l-iTime+float(i) +vec3(0,23,21) ) )*C[i], 1 ) // + border

            #define blend(i) O += (1.-O.a) * col(i) * C[i]

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
                fixed4 O;
                fixed2 U = uv;

                O -= O;
                
                float a = atan2(U.y,U.x), l = length(U);
                l =  2.*l; a =  30.*a/6.28;
                
                vec4 s = l-vec4(0,0,.5,.5),
                A = fract( a-vec4(.25,.75,0,.5) )-.5, L = fract(s-iTime) - .5, // 4 overlapping polar tilings
                r = sqrt(A*A*abs(s) + L*L),                         // ellipse (s*s would be const width)
                C = smoothstep(.1,0., r-.3);                        // 4 feathers mask
                
                int c = 2* int( L.z > L.x );                             // sort ranks
                ivec2 T = ivec2( A[1+c] > A[0+c], A[1+2-c] > A[0+2-c] ); // sort rows

                blend(  T.x  +  c  );                                    // blend by sorted order
                blend( 1-T.x +  c  );
                blend(  T.y  + 2-c );
                blend( 1-T.y + 2-c );

                return O;
            }
            ENDCG
        }
    }
}
