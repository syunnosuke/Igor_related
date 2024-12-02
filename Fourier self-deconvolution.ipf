#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//2023.12.10 Syunnosuke SUWA coded
//UI
Menu "macroPanel"
	"FSD", /Q,  winFSD()
End
Window winFSD() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(75,111,370,429) as "FSD"
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 37,64,"wv"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 37,91,"rs"
	SetDrawEnv fname= "Comic Sans MS",fsize= 15,fstyle= 1
	DrawText 18,38,"Fourier Self-Deconvolution"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 24,143,"parameters"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 40,252,"apodization width"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 40,173,"line shape"
	SetDrawEnv dash= 3,fillpat= 0
	DrawRect 17,149,277,310
	Slider sd_LS,pos={40,175},size={214,57},proc=sd_ls_range
	Slider sd_LS,limits={0,10,0.1},value= 2.8,side= 2,vert= 0
	SetVariable sv_wv,pos={70,49},size={150,16},proc=sv_wvName
	SetVariable sv_wv,userdata(ResizeControlsInfo)= A"!!,Hq!!#Aj!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable sv_wv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable sv_wv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable sv_wv,value= _STR:"wave"
	SetVariable sv_rs,pos={70,75},size={150,16},proc=sv_rsName
	SetVariable sv_rs,value= _STR:"rs"
	Button bt_set,pos={68,97},size={70,20},proc=bt_FSDsetCalc,title="Set calc"
	Slider sd_AW,pos={40,250},size={214,57},proc=sd_aw_range
	Slider sd_AW,userdata(ResizeControlsInfo)= A"!!,Fs!!#AI!!#Ae!!#>Zz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Slider sd_AW,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Slider sd_AW,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider sd_AW,limits={0,1,0.05},value= 0.4,side= 2,vert= 0
	SetVariable sv_LS_sliderMax,pos={208,156},size={50,16},proc=sv_ls_SldrMax
	SetVariable sv_LS_sliderMax,value= _NUM:10
	SetVariable sv_AW_sliderMax,pos={208,235},size={50,16},proc=sv_aw_SldrMax
	SetVariable sv_AW_sliderMax,value= _NUM:1
	ValDisplay vd_ls,pos={121,158},size={25,13},limits={0,0,0},barmisc={0,1000}
	ValDisplay vd_ls,value= _NUM:2.8
	ValDisplay vd_aw,pos={165,237},size={25,13},limits={0,0,0},barmisc={0,1000}
	ValDisplay vd_aw,value= _NUM:0.3
EndMacro

//Panel functions
//root:set_wvName, root:set_rsName

Function sv_wvName(sva) : SetVariableControl
//wave名を取得
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			string/G root:set_wvName = sva.sval
			break
		case 3: // Live update	
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function sv_rsName(sva) : SetVariableControl
//raman_shift名を取得
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			string/G root:set_rsName = sva.sval
			break
		case 3: // Live update	
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function  sv_ls_SldrMax(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable/G root:set_lsSldMx = sva.dval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function  sv_aw_SldrMax(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable/G root:set_awSldMx = sva.dval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function sd_ls_range(sa) : SliderControl
//スライダー LS
	STRUCT WMSliderAction &sa
	NVAR val_lsSmx = root:set_lsSldMx //
	Slider sd_LS, limits = {0, val_lsSmx,0.1}
	variable/G root:sd_ls_csrVal = sa.curval
	
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				//variable/G root:sd_ls_csrVal = sa.curval
				NVAR sd_ls_val =  root:sd_ls_csrVal 
				NVAR sd_aw_val =  root:sd_aw_csrVal 
				
				Slider sd_LS, limits = {0, val_lsSmx,0.1}
				//FSD を計算
				//既にあるwaveを変更する形で計算
				SVAR strWv =root:set_wvName
				SVAR strRs =root:set_rsName
				wave wv = $strWv
				wave rs = $strRs
				//print(sd_ls_val)
				//print(sd_aw_val)
				DoWindow/F $("FSD")
				ValDisplay vd_ls value =_NUM: sd_ls_val
				
				//calc update
				SVAR strWv =root:set_wvName
				SVAR strRs =root:set_rsName
				wave wv = $strWv
				wave rs = $strRs
				FSD_calc(wv, rs, sd_ls_val, sd_aw_val)
				
			endif
			break
	endswitch
	return 0
End

Function sd_aw_range(sa) : SliderControl
//スライダー AW
	STRUCT WMSliderAction &sa
	NVAR val_awSmx = root:set_awSldMx 
	Slider sd_AW, limits = {0, val_awSmx,0.05}
	variable/G root:sd_aw_csrVal = sa.curval
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				//variable/G root:sd_aw_csrVal = sa.curval
				NVAR sd_aw_val =  root:sd_aw_csrVal 
				NVAR sd_ls_val =  root:sd_ls_csrVal 
				
				Slider sd_AW, limits = {0, val_awSmx,0.05}
				//FSDを計算
				//既にあるwaveを変更する形で計算
				SVAR strWv =root:set_wvName
				SVAR strRs =root:set_rsName
				wave wv = $strWv
				wave rs = $strRs
				
				DoWindow/F $("FSD")
				ValDisplay vd_aw value =_NUM: sd_aw_val
				
				//calc update
				SVAR strWv =root:set_wvName
				SVAR strRs =root:set_rsName
				wave wv = $strWv
				wave rs = $strRs
				FSD_calc(wv, rs, sd_ls_val, sd_aw_val)
				
			endif
			break
	endswitch
	return 0
End

Function bt_FSDsetCalc(ba) : ButtonControl
//wv ,rs, LS, AWを取得、計算を実行する
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			SVAR strWv =root:set_wvName
			SVAR strRs =root:set_rsName
			wave wv = $strWv
			wave rs = $strRs
			
			// ls, awの取得
			variable ls = 5
			variable aw = 0.25
			//sliderのvalueをセット x2
			Slider sd_LS, limits = {0, ls *2, 0.1}
			Slider sd_AW, limits = {1, aw *2, 0.05}
			
			
			print("Fourie Self-deconvolution ::: " + nameofwave(wv) +", " +(nameofwave(rs)))
			wave wvRes = FSD_calc(wv, rs, ls, aw)
			Display
			AppendToGraph wv vs rs
			AppendToGraph wvRes vs rs
			//ModifyGraph lsize=1.5
			GradationRainbow()
			
			//sの値をBoxにセット
			NVAR sd_aw_val =  root:sd_aw_csrVal 
			NVAR sd_ls_val =  root:sd_ls_csrVal 
			DoWindow/F $("FSD")
			ValDisplay vd_ls value =_NUM: sd_ls_val
			ValDisplay vd_aw value =_NUM: sd_aw_val
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//Basic functions
function/WAVE FSD_calc(wv, rs, df, l)
	wave wv, rs //interp (1 /cm/step)済みwave
	variable df, l	
	string wvName = nameofwave(wv)
	
	// FFT
	FFT /OUT=1 /DEST =$(wvName+"_fft") wv
	wave wvFFT =$(wvName+"_fft")
	
	//Boxcar
	duplicate/o wvFFT  $(nameofwave(wvFFT)+"_bx")
	wave/C wvFFT_d1 =$(nameofwave(wvFFT)+"_bx")
	wvFFT_d1= (x <= l) ? wvFFT_d1[p]: 0
	
	// line shape
	duplicate/o wvFFT_d1  $(nameofwave(wvFFT)+"_l")
	wave/C wvFFT_d2 =$(nameofwave(wvFFT)+"_l")
	wvFFT_d2 *= exp(2*PI* df*x)
	
	// apodization
	duplicate/o wvFFT_d2  $(nameofwave(wvFFT)+"_ap")
	wave/C wvFFT_d3 =$(nameofwave(wvFFT)+"_ap")
	wvFFT_d3 *=(1 - x/l)^2
	//IFFT

	make/o/n=(dimsize(wv,0)) $(wvName+"_fsd")
	wave wvRes =$(wvName+"_fsd")
	IFFT /DEST= $(wvName+"_fsd") wvFFT_d3
	
	return wvRes
end



