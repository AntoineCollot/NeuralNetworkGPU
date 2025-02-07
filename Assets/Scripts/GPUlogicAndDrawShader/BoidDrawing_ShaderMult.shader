﻿Shader "Custom/BoidDrawing_ShaderMult"
{
	
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "ForceNoShadowCasting"="True"}
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert noshadow nolightmap
		#pragma instancing_options procedural:setup

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

		#include "UnityCG.cginc"
		struct Boid
		{
			float3 position;
			float3 direction;
		};
		
        struct Input
        {
            float2 uv_MainTex;
          float2 uv_BumpMap;
        };
		 
		 struct appdata_custom {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 texcoord : TEXCOORD0;
            float4 tangent : TANGENT;
 
            uint id : SV_VertexID;
            uint inst : SV_InstanceID;

            UNITY_VERTEX_INPUT_INSTANCE_ID
         };
		
		#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
		StructuredBuffer<Boid> boidsBuffer;
		#endif
		float4x4 _LookAtMatrix;
        float3 _BoidPosition;
		uniform half _BoidSize;
		uniform half _RepeatAreaSize;
		uniform half _BoidCount;
		
        float4x4 look_at_matrix(float3 at, float3 eye, float3 up) {
            float3 zaxis = normalize(at - eye);
            float3 xaxis = normalize(cross(up, zaxis));
            float3 yaxis = cross(zaxis, xaxis);
            return float4x4(
                xaxis.x, yaxis.x, zaxis.x, 0,
                xaxis.y, yaxis.y, zaxis.y, 0,
                xaxis.z, yaxis.z, zaxis.z, 0,
                0, 0, 0, 1
            );
        }

//We get 27 times the number of boids, so we read the modulo of the id and offset it based on the original value
        void setup()
        {
			#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			uint moduloId = unity_InstanceID%_BoidCount;
			int batch = unity_InstanceID/4000;
            _BoidPosition = boidsBuffer[moduloId].position;
			//Move the boid based on its batch
			_BoidPosition.x += _RepeatAreaSize *((batch / 9) % 3 - 1);
			_BoidPosition.y += _RepeatAreaSize *((batch / 3) % 3 - 1);
			_BoidPosition.z += _RepeatAreaSize *(batch % 3 - 1);
            _LookAtMatrix = look_at_matrix(_BoidPosition, _BoidPosition + (boidsBuffer[moduloId].direction * -1), float3(0.0, 1.0, 0.0));
			#endif
        }
		
		
		void vert(inout appdata_custom v)
        {
			#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			v.vertex *= _BoidSize;
            v.vertex = mul(_LookAtMatrix, v.vertex);
            v.vertex.xyz += _BoidPosition;
			#endif
        }

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		sampler2D _BumpMap;
        sampler2D _MainTex;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
			o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
