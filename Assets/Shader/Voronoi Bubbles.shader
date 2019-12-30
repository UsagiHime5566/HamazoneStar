Shader "Unlit/Voronoi Bubbles"
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

            float hash1( float n ) {
                return fract(sin(n)*43758.5453);
            }
            vec2  hash2( vec2  p ) {
                p = vec2(
                dot(p,vec2(127.1,311.7)),
                dot(p,vec2(269.5,183.3))
                );
                return fract(sin(p)*43758.5453);
            }
            vec3 hash3( vec3  p ) {
                p = vec3(
                dot(p,vec3(421.9,137.2,159.5)),
                dot(p,vec3(127.1,311.7,753.7)),
                dot(p,vec3(269.5,183.3,459.3))
                );
                return fract(sin(p)*43758.5453);
            }
            vec3 hsv2rgb(vec3 c) {
                vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            vec4 voronoi( in vec2 x)
            {
                vec2 n = floor( x );
                vec2 f = fract( x );

                const int _size = 4;
                vec4 m = vec4( 0.0, 0.0, 0.0, 1.0 );
                for( int j=-_size; j<=_size; j++ )
                for( int i=-_size; i<=_size; i++ )
                {
                    vec2 g = vec2( float(i),float(j) );
                    vec2 o1 = hash2( n + g );
                    
                    // animate
                    vec2 o = 0.5 + 0.5*sin( iTime*2. + 6.2831*o1 );

                    // distance to cell		
                    float d = length(g - f + o)*pow(sin(iTime + o1.x * 1000.)+1.5,3.);
                    
                    // do the smoth min for colors and distances		
                    vec3 col = hsv2rgb(vec3(o,1.));
                    float h = smoothstep( 0.0, 1.0, 0.5 + 0.5*(m.w-d)/pow(sin(iTime+o.x)*.1+.1,1.1) );
                    
                    m.w   = mix( m.w,     d, h );
                    m.xyz = mix( m.xyz, col, h );
                }
                
                return m;
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

                vec2 p = uv;
                
                vec4 v = voronoi( (sin(iTime)*2.+13.)*p );
                return vec4(v.xyz,1.);
            }
            ENDCG
        }
    }
}
