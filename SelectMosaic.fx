#define AA_FLG 0
//edit by KarlvonDonitz

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float Intensity : CONTROLOBJECT < string name = "(self)"; string item = "Si";>;
float XIntensity : CONTROLOBJECT < string name = "(self)"; string item = "X";>;
float YIntensity : CONTROLOBJECT < string name = "(self)"; string item = "Y";>;
float Flag : CONTROLOBJECT < string name = "(self)"; string item = "Rx";>;
float time: TIME;
float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;

static float2 SampStep = (float2(1,1)/ViewportSize);


float4 ClearColor = {0,0,0,1};
float ClearDepth  = 1.0;


texture2D ScnMap : RENDERCOLORTARGET <

    int MipLevels = 1;
    bool AntiAlias = AA_FLG;
    string Format = "A8R8G8B8" ;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    AddressU  = CLAMP;
    AddressV = CLAMP;
    Filter = NONE;
};

texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    string Format = "D24S8";
>;

texture ColorMask: OFFSCREENRENDERTARGET <
    string Description = "Color Mask for SelectColorDisplacement.fx";
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = 0;
    string DefaultEffect = 
        "* = OFF.fx";
>;

sampler Mask = sampler_state {
	texture = <ColorMask>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	Filter = NONE;
};


struct VS_OUTPUT {
    float4 Pos			: POSITION;
	float2 Tex			: TEXCOORD0;
};


VS_OUTPUT VS_passMain( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out = (VS_OUTPUT)0; 

    Out.Pos = Pos; 
    Out.Tex = Tex;
    return Out;
}

float4 PS_passMain(float2 Tex: TEXCOORD0) : COLOR
{   
	float4 Color = tex2D(ScnSamp,Tex);
	float2 fTexSize=ViewportSize;
    float2 fmosaicSize= float2(XIntensity*Intensity/10,YIntensity*Intensity/10);
	float2 fintXY=float2(Tex.x*fTexSize.x,Tex.y*fTexSize.y);
	float2 MosicUV=float2(int(fintXY.x/fmosaicSize.x)*fmosaicSize.x,int(fintXY.y/fmosaicSize.y)*fmosaicSize.y);
	float2 UVMosaic=float2(MosicUV.x/fTexSize.x,MosicUV.y/fTexSize.y);
    float Flag = tex2D(Mask,UVMosaic).r;
	if (Flag == 0) {
      Color = tex2D(ScnSamp,UVMosaic);
	}
    return Color;
}

technique Color <
    string Script = 
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"
        
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "Pass=Main;"
    ;
> {

    pass Main < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passMain();
        PixelShader  = compile ps_3_0 PS_passMain();
    }
}
