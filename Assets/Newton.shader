Shader "Unlit/Newton"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _R1 ("R1" , Vector) = (1 , 0 , 0 , 0)
        _R2 ("R2" , Vector) = (1 , 1 , 0 , 0)
        _R3 ("R3" , Vector) = (0 , 2 , 0 , 0)
        _R4 ("R4" , Vector) = (-1 , -0.5 , 0 , 0)
        _R5 ("R5" , Vector) = (0.5 , -2 , 0 , 0)
        //Roots of some polynomial
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
            float2 _R1 , _R2 , _R3 , _R4 , _R5;

            float2 multiply(float2 a , float2 b)
            {
                float2 p;
                p.x = (a.x * b.x) - (a.y * b.y);
                p.y = (a.x * b.y) + (a.y * b.x);
                return p;
                //This is the equation of what you get when simplifying (a.x + a.yi) * (b.x + b.yi)
            }

            float2 divide (float2 a , float2 b)
            {
                float2 bconj = float2(b.x , -b.y); // Conjugate of the divisor (b)

                float2 n = multiply(a , bconj); // multiply dividend by bconj to get numerator

                float d = length(b);
                d = d * d;
                // the denominator is b * its conjugate, becoming ||b||^2

                n /= d; // dividing by the calculated real number divisor

                return n; // returns n
                // n being the result after veing divided
            }

            float2 f(float2 z)
            {
                // Evaluate the polynomial at the point z

                float2 r = float2(1 , 0);
                // I called it r for the product ... I guess for the return value

                r = multiply(r , z - _R2);
                r = multiply(r , z - _R3);
                r = multiply(r , z - _R1);
                r = multiply(r , z - _R4);
                r = multiply(r , z - _R5);
                // multiply by z - each root(evaluating in factored form)

                return r; // returns the result
            }

            float2 fder(float2 z)
            {
                // Evaluate derivitive of the polonomial

                float2 a = f(z); // polynomial at z

                float2 delta = float2(0.001 , 0); // small value to approach 0

                float2 b = f(z + delta); // polonomial at shifted z

                float2 d = b - a; // difference in the values

                d = divide(d , delta); // divide by the small step

                return d;
            }

            float2 steplen(float2 z)
            {
                // calculate step length

                float2 a = f(z);
                float2 b = fder(z);
                // function and its derivitive at the point z

                float2 s = divide(-a , b); // divide value by derivitive and negate for step size

                return s;
            }

            float2 iterate(float2 z , float cycles)
            {
                int n = 0;
                while (n < cycles) // Repeat cycles
                {
                    float2 d = steplen(z); // get step length

                    z += d; // change guess by step length

                    if (length(d) < 0.001)
                    {
                        break;
                    }
                    // Stop if the step length is very small meaning we are at a root

                    n += 1; // increment iteration
                    //Totally didn't crash Unity at least once forgetting this line
                }
                return z; // the root that was found
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 z = i.uv;

                if (length(z - _R1) < 0.1)
                {
                    float2 n = 0.2 * _R1 + 0.4;
                    return float4 (n.x , n.y , 0 , 1);
                }
                if (length(z - _R2) < 0.1)
                {
                    float2 n = 0.2 * _R2 + 0.4;
                    return float4 (n.x , n.y , 0 , 1);
                }
                if (length(z - _R3) < 0.1)
                {
                    float2 n = 0.2 * _R3 + 0.4;
                    return float4 (n.x , n.y , 0 , 1);
                }
                if (length(z - _R4) < 0.1)
                {
                    float2 n = 0.2 * _R4 + 0.4;
                    return float4 (n.x , n.y , 0 , 1);
                }
                if (length(z - _R5) < 0.1)
                {
                    float2 n = 0.2 * _R5 + 0.4;
                    return float4 (n.x , n.y , 0 , 1);
                }
                // If the point is close to a root, color it with that root for reference
                // I know that the Idea is that it is suppossed to find the roots
                // but knowing where they are can be helpful and nice
                // so I decided to color them


                float2 n = 0.2 * iterate(z , 50) + 0.3;
                return float4 (n.x , n.y , 0 , 1);
                // If its not near a root, color it based on the function to find a root
            }
            ENDCG
        }
    }
}
