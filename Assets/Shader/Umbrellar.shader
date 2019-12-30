Shader "Unlit/Umbrellar "
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

            float sdfCircle(fixed2 center, float radius, fixed2 coord )
            {
                fixed2 offset = coord - center;
                
                return sqrt((offset.x * offset.x) + (offset.y * offset.y)) - radius;
            }

            float sdfEllipse(fixed2 center, float a, float b, fixed2 coord)
            {
                float a2 = a * a;
                float b2 = b * b;
                return (b2 * (coord.x - center.x) * (coord.x - center.x) + 
                a2 * (coord.y - center.y) * (coord.y - center.y) - a2 * b2)/(a2 * b2);
            }

            float sdfLine(fixed2 p0, fixed2 p1, float width, fixed2 coord)
            {
                fixed2 dir0 = p1 - p0;
                fixed2 dir1 = coord - p0;
                float h = clamp(dot(dir0, dir1)/dot(dir0, dir0), 0.0, 1.0);
                return (length(dir1 - dir0 * h) - width * 0.5);
            }

            float sdfUnion( const float a, const float b )
            {
                return min(a, b);
            }

            float sdfDifference( const float a, const float b)
            {
                return max(a, -b);
            }

            float sdfIntersection( const float a, const float b )
            {
                return max(a, b);
            }

            fixed4 render(float d, fixed3 color, float stroke)
            {
                //stroke = fwidth(d) * 2.0;
                float anti = fwidth(d) * 1.0;
                fixed4 strokeLayer = fixed4(_fixed3(0.05), 1.0-smoothstep(-anti, anti, d - stroke));
                fixed4 colorLayer = fixed4(color, 1.0-smoothstep(-anti, anti, d));

                if (stroke < 0.000001) {
                    return colorLayer;
                }
                return fixed4(lerp(strokeLayer.rgb, colorLayer.rgb, colorLayer.a), strokeLayer.a);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. fmod 改 ffmod  or  #define fmod(x,y) (x-y*floor(x/y))
                //step4. lerp 改 lerp
                //step5. fract 改 frac
                //step6. mat2 矩陣 改為 fixed2x2
                //step7. 矩陣運算 a*b 須改為 mul(a,b)
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv;
                //uv = 2.0 * uv - 1.0;
                fixed4 fragColor = _fixed4(0);

                //float size = min(iResolution.x, iResolution.y);
                //float pixSize = 1.0 / size;
                //fixed2 uv = fragCoord.xy / iResolution.x;
                float stroke = 1.5;
                fixed2 center = fixed2(0.5, 0.5);
                
                float a = sdfEllipse(fixed2(0.5, center.y*2.0-0.34), 0.25, 0.25, uv);
                float b = -1;
                //b = sdfIntersection(a, b);
                fixed4 layer1 = render(b, fixed3(0.32, 0.56, 0.53), fwidth(b) * 2.0);
                
                // Draw strips
                fixed4 layer2 = layer1;
                float t, r0, r1, r2, e, f;
                fixed2 sinuv = fixed2(uv.x, (sin(uv.x*40.0)*0.02 + 1.0)*uv.y);
                for (float i = 0.0; i < 10.0; i++) {
                    t = fmod(_Time.y + 0.3 * i, 3.0) * 0.2;
                    r0 = (t - 0.15) / 0.2 * 0.9 + 0.1;
                    r1 = (t - 0.15) / 0.2 * 0.1 + 0.9;
                    r2 = (t - 0.15) / 0.2 * 0.15 + 0.85;
                    e = sdfEllipse(fixed2(0.5, center.y*2.0+0.37-t*r2), 0.7*r0, 0.35*r1, sinuv);
                    f = sdfEllipse(fixed2(0.5, center.y*2.0+0.41-t), 0.7*r0, 0.35*r1, sinuv);
                    f = sdfDifference(e, f);
                    //f = sdfIntersection(f, b);
                    fixed4 layer = render(f, fixed3(1.0, 0.81, 0.27), 0.0);
                    layer2 = lerp(layer2, layer, layer.a);
                }
                
                fragColor.rgb = lerp(fragColor.rgb, layer2.rgb, layer2.a);
                
                fragColor.rgb = pow(fragColor.rgb, _fixed3(1.0/2.2));

                return fragColor;
            }
            ENDCG
        }
    }
}
