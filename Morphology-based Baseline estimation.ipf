// reference
//Perez-Pueyo R, Soneira MJ, Ruiz-Moreno S. 
//Morphology-Based Automated Baseline Removal for Raman Spectra of Artistic Pigments. Applied Spectroscopy.
//2010;64(6):595-600. doi:10.1366/000370210791414281
//

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Resize Controls>
#include <Rewrite Control Positions>

function/WAVE erosion(wv, s)
	wave wv
	variable s
	
	duplicate/O wv $( nameofwave(wv)+"_E")
	wave wvE =  $( nameofwave(wv)+"_E")

	variable i
	for (i=0; i<dimsize(wv,0);i+=1)
		if(i<s)
		wvE[i] = wavemin(wv, 0, i+s);
		elseif (i+s> dimsize(wv,0)) 
		wvE[i] = wavemin(wv, i-s, dimsize(wv,0));
		else
		wvE[i] = wavemin(wv,i-s, i+s);
		endif
	endfor
	return  wvE
end

function/WAVE dilation(wv, s)
	wave wv
	variable s
	
	duplicate/O wv  $( nameofwave(wv)+"_D")
	wave wvD =  $( nameofwave(wv)+"_D")
	
	variable i
	for (i=0; i<dimsize(wv,0);i+=1)
		if(i<s)
		wvD[i] = wavemax(wv, 0, i+s);
		elseif (i+s> dimsize(wv,0)) 
		wvD[i] = wavemax(wv, i-s, dimsize(wv,0));
		else
		wvD[i] = wavemax(wv,i-s, i+s);
		endif
	endfor
	return  wvD
end

function/WAVE opening(wv, s)
	wave wv
	variable s
	
	duplicate/O wv  $( nameofwave(wv)+"_O")
	wave wvO =  $( nameofwave(wv)+"_O")
	
	wave wvTemp = dilation(erosion(wv,s),s)
	wvO[] = wvTemp
	return  wvO
end

function/WAVE ModifBG(wv,s)
	wave wv
	variable s
	
	duplicate/O wv $( nameofwave(wv)+"_M")
	wave wvM =  $( nameofwave(wv)+"_M")
	
	wave wvTemp1 = dilation(opening(wv,s),s)
	wave wvTemp2 = erosion(opening(wv,s),s)
	wvM[] = (wvTemp1 + wvTemp2)/2
	return  wvM
end

function/WAVE OptBG(wv,s)
	wave wv
	variable s
	
	duplicate/O wv $( nameofwave(wv)+"_Opt")
	wave wvOpt =  $( nameofwave(wv)+"_Opt")
	
	wave wvTemp1= opening(wv,s)
	wave wvTemp2 = ModifBG(wv,s)
	
	variable i
	for ( i=0 ; i< dimsize(wv,0); i+=1)
		wvOpt[i] = min(wvTemp1[i] ,wvTemp2[i])
	endfor
	return  wvOpt
end

function wvAllClose (wv1, wv2 [, atol, rtol])
	wave wv1, wv2
	variable atol, rtol
	if(paramisdefault(atol))
		atol  = 1e-05
	endif
	if(paramisdefault(rtol))
		rtol  = 1e-05
	endif
	
	 
	if( dimsize(wv1,0) != dimsize(wv2,0))
		print("dimension mismatch")
		return -1;
	endif 
	
	variable res_flag = 1
	variable i
	for (i=0; i< dimsize(wv1,0) ;i+=1)
		if( abs(wv1[i] - wv2[i]) > atol + rtol* abs(wv2[i]))
			res_flag = 0
			break
		endif
	endfor 
	return res_flag
end


Function BGsbtr_MorphBsd(wv, rs [,atol , rtol, cycle_limit])
	wave wv ,rs
	variable atol, rtol, cycle_limit
	
	if(paramisdefault(atol))
		atol  = 1e-05
	endif
	if(paramisdefault(rtol))
		rtol  = 1e-05
	endif
	if(paramisdefault(cycle_limit))
		cycle_limit = 2000
	endif

	
	variable s = 1
	variable i
	
	make/o/n=(dimsize(wv,0)) $"tempWave1", $"tempWave2", $"tempWave3"
	wave wvTemp1 =  $"tempWave1",wvTemp2 =  $"tempWave2",wvTemp3 =  $"tempWave3"
	for (i=0; i<dimsize(wv,0) ;i+=1)
		switch (i)
			case 1:
				wave w1 = opening(wv, i)
				wvTemp1 = w1
			case 2:
				wave w2 = opening(wv, i)
				wvTemp2 = w2
			case 3:
				wave w3 = opening(wv, i)
				wvTemp3 = w3
			default:
				wvTemp1 = wvTemp2
				wvTemp2 = wvTemp3
				wave w4 = opening(wv,i)
				wvTemp3 = w4
		endswitch
		if(i < 3)
			continue;
		elseif (wvAllClose(wvTemp1, wvTemp2, atol = atol, rtol = rtol) && wvAllClose(wvTemp1, wvTemp3, atol = atol, rtol = rtol) && wvAllClose(wvTemp2, wvTemp3, atol = atol, rtol = rtol))
			s = i-2
			print("@ estimated width parameter   s =  " + num2str(s))
			variable root:s_res = s
			break
		endif	
	endfor
	

	wave BG = OptBG(wv,s)
	
	duplicate/O wv $(nameofwave(wv) + "_bg")
	wave wvBG = $(nameofwave(wv) + "_bg")
	wvBG = BG;

	string wRes= nameofwave(wv) + "_bgSb"
	duplicate/o wv $wRes
	wave wvRes =$wRes
	wvRes =  wv -wvBG
	
	print("@ estimate BG spectrum is "+ nameofwave(wvBG))
	print("@ BG subtracted spectrum is "+ nameofwave(wvRes))
	
	Display
	AppendToGraph wv vs rs
	AppendToGraph wvBG vs rs
	AppendToGraph wvRes vs rs
	ModifyGraph lsize=1.5
	GradationRainbow()
	killwaves wvTemp1, wvTemp2, wvTemp3
	
End

Function BGsbtr_MorphBsd_upd(wv, rs, s [,atol , rtol, cycle_limit])
	wave wv ,rs
	variable s, atol, rtol, cycle_limit
	
	if(paramisdefault(atol))
		atol  = 1e-05
	endif
	if(paramisdefault(rtol))
		rtol  = 1e-05
	endif
	if(paramisdefault(cycle_limit))
		cycle_limit = 200
	endif
	
	wave BG = OptBG(wv,s)
	wave wvBG = $(nameofwave(wv) + "_bg")
	wvBG = BG;

	string wRes= nameofwave(wv) + "_bgSb"
	wave wvRes =$wRes
	wvRes =  wv -wvBG
	
End



// Panel functions
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

Function bt_getSetNames(ba) : ButtonControl
//wv ,rsをwaveとして取得、計算を実行する
	STRUCT WMButtonAction &ba
	
	SVAR strWv =root:set_wvName
	SVAR strRs =root:set_rsName
	wave wv = $strWv
	wave rs = $strRs
	NVAR s_show = root:s_res
	
	if(dimsize(wv,1) >1)
		print("dimension mismatch. it must be lower than 1.")
		return -1
	elseif(dimsize(wv,1) ==1)
		Redimension /N=(dimsize(wv,0),0) wv
	endif

	switch( ba.eventCode )
		case 2: // mouse up
			print("@Morphology based BG subtraction for wave ::: " + nameofwave(wv) )
			//setscale 合わせる
			
			//SetScale/P x, 0, rs[1] -rs[0], wv
			BGsbtr_MorphBsd(wv, rs)
			//sの値をBoxにセット
			DoWindow/F $("BGsubtraction")
			ValDisplay vd_s,value= _NUM: s_show

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function  sv_SldrMax(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	//初期値の決定
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable/G root:set_SldMx = sva.dval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function sd_s_range(sa) : SliderControl
//スライダー
	STRUCT WMSliderAction &sa
	NVAR valSmx = root:set_SldMx //
	variable/G root:sd_csrVal = sa.curval
	
	NVAR sd_val =  root:sd_csrVal 
	Slider sd_s, limits = {1, valSmx,1}
	
	SVAR strWv =root:set_wvName
	SVAR strRs =root:set_rsName
	wave wv = $strWv
	wave rs = $strRs
	
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set				
				BGsbtr_MorphBsd_upd(wv, rs, sa.curval)
				
				DoWindow/F $("BGsubtraction")
				ValDisplay vd_s value =_NUM: sd_val		
			endif
			break
	endswitch
	return 0
End

//UI
Menu "macroPanel"
	"BG subtraction", /Q,  MBbgSubtractionWin()
End
Function MBbgSubtractionWin()
	if(strlen(WinList("BGsubtraction",";","")))
		DoWindow/F $("BGsubtraction")
		return 0
	endif

	NewPanel /W=(124,168,559,434) as "BGsubtraction"
	DoWindow $("BGsubtraction")
	SetDrawLayer UserBack
	SetDrawEnv fname= "Comic Sans MS",fsize= 15,fstyle= 1
	DrawText 31,44,"Morphology-based BG subtraction"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 50,78,"wv"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 50,114,"rs"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 47,175,"Manual parameter adjustment"
	SetDrawEnv fname= "Arial",fsize= 15
	DrawText 50,234,"s"
	
	Button bt_set,pos={47,129},size={70,20},proc=bt_getSetNames,title="Set calc"
	SetVariable sv_wave,pos={83,63},size={150,16},proc=sv_wvName
	SetVariable sv_wave,userdata(ResizeControlsInfo)= A"!!,Hq!!#Aj!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable sv_wave,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable sv_wave,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable sv_wave,value= _STR:"prod_ms_I_Av"
	SetVariable sv_rs,pos={83,98},size={150,16},proc=sv_rsName,value= _STR:"rs_I"
	Slider sd_s,pos={142,186},size={214,51},proc=sd_s_range
	Slider sd_s,userdata(ResizeControlsInfo)= A"!!,Fs!!#AI!!#Ae!!#>Zz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Slider sd_s,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Slider sd_s,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider sd_s,limits={1,300,1},value= 50,side= 2,vert= 0
	SetVariable sv_sliderMax,pos={363,218},size={50,16},proc=sv_SldrMax
	SetVariable sv_sliderMax,value= _NUM:300
	ValDisplay vd_s,pos={83,220},size={50,13},limits={0,0,0},barmisc={0,300}
	ValDisplay vd_s,value= _NUM:0
End
