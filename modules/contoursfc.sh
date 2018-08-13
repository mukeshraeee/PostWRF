#!/bin/bash
#PostWRF Version 1.0 (May 2018)
#This shell script uses a NCL code to draw surface contour maps.
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

curdir=`pwd`
trap 'my_exit; exit' SIGINT SIGQUIT
count=0

my_exit()
{
curdir2=`pwd`
rm timestep_file 2> /dev/null
rm .AllWRFVariables 2> /dev/null
if [[ $curdir != $curdir2 ]]; then
wrflist=`ls wrfout*`
totnom=`echo $wrflist | wc -w`
rmcounter=1
rm *.png 2> /dev/null
while [ $rmcounter -le $totnom ]; do
file=`echo $wrflist | cut -d' ' -f$rmcounter`
 if [[ -L "$file" ]]; then
 rm $file 2> /dev/null
 fi
rmcounter=$((rmcounter+1))
done
rmdir ../outputs_$wrfout2 2> /dev/null

unset rmcounter
fi
}
 echo -e "\n Drawing surface contour maps for $contourselect ..."
    echo -e "\n Specify The Method Of Drawing Contours (1 or 2):"
    select contvar in "Automatic" "Manual"
      do
       case $contvar in
        Automatic) echo -e "\nContour Lines Will Be Set Automatically ...";;
        Manual) echo ""
                read -p "Contour Lines Min Value (press Enter for the best value): " Min
                if [ -z ${Min} ]; then
                 echo " Got no input. Best Min value will be set automatically."
                 Min="NULL"
                fi
                echo ""
                read -p "Contour Lines Max Value (press Enter for the best value): " Max
                if [ -z ${Max} ]; then
                 echo " Got no input. Best Max value will be set automatically."
                 Max="NULL"
                fi
                echo ""
                  Intv="NULL";;
        *)echo -e "\nContours Will Be Plotted Automatically.";;
       esac
       break
    done

    wrfout2=`echo $wrfout | awk -F/ '{print $NF}'`  #For naming, NCL must be run by wrfout, not wrfout2
    ncl modules/timestep.ncl > timestep_file
     echo " "`tail -n 1 timestep_file | cut -d " " -f 2-`
     rm timestep_file
     read -p "Specify Time_Step(s) Between The Images (Default=1): " tstep
    if [ -z "$tstep" ]; then
       echo Time_Step Has Been Set To 1
       tstep=1
    fi
    export tstep

       echo -e "\nSelect a color pattern from the list below (a number from 1 to 10):"
       select colpal in "Rainbow-start_from_blue" "Rainbow-start_from_red" "Rainbow+white-start_from_white" "Blue..Red" "White..Blue" "White..Red" "White..Green" "White..Yellow..Orange..Red" "White..Black" "Black..White"
       do
	case $colpal in
		Rainbow-start_from_blue) colpal="rainbow1";;
		Rainbow-start_from_red) colpal="MPL_gist_rainbow1";;
		Rainbow+white-start_from_white) colpal="WhBlGrYeRe1";;
		Blue..Red) colpal="BlueRed1";;
		White..Yellow..Orange..Red) colpal="WhiteYellowOrangeRed1";;
		White..Blue) colpal="WhiteBlue1";;
		White..Red) colpal="MPL_Reds1";;
		White..Green) colpal="WhiteGreen1";;
	 	White..Black) colpal="WandB";;
	 	Black..White) colpal="BandW";;
		*) echo "Rainbow color pattern has been selected"; colpal="rainbow1";;
       esac
       break
      done 

      echo -e "\n Format Of The Images: 1, 2, 3, or 4?"
     select imgfmt in "x11" "pdf" "png" "animated_gif"
      do
       case $imgfmt in
        x11);;
        pdf);;
        png);;
        animated_gif);;
        *) echo "Output Images Will Be 'X11'"; imgfmt="x11";;
       esac
       export imgfmt
       break
      done

      if [[ ${imgfmt} == "animated_gif" ]]; then
       echo -e "\n Speed of the Amimated GIF: 1, 2, or 3?"
       select anim_spd in "slow" "medium" "fast"
        do
         case $anim_spd in
          slow) anim_spd="75";;
          medium) anim_spd="50";;
          fast) anim_spd="25";;
          *) echo "Animation Speed Will Be 'medium'"; anim_spd="50";;
         esac
         break
        done
      fi

     if [[ ${imgfmt} == "x11" ]]; then
      outname="nclplot"
     else
    read -p "`echo -e "\n "`Specify The Output File Name (Press Enter for the default name): " outname2
     cnpostname=`echo $wrfout2 | cut -d "_" -f2-3`
      if [ -z "$outname2" ]; then
       outname=`echo "contour-surface-"$contourselect"-"$cnpostname`
       echo "  Contour file will be named $outname"
      else
       outname=`echo $outname2"-"$cnpostname`
      fi
     fi
    export outname

       export colpal
       export contvar
       export Min
       export Max
       export Intv

    if [[ ${imgfmt} == "x11" ]]; then
      ncl modules/contoursfc.ncl
     else
       mkdir -p outputs_$wrfout2
       cd outputs_$wrfout2
       ln -s ../wrfout* .
       ln -s ../.AllWRFVariables .
       ncl ../modules/contoursfc.ncl
       if [[ ${imgfmt} == "animated_gif" ]]; then
        convert -delay $anim_spd *.png $outname.gif
        rm *.png
       fi
       rm wrfout*
       rm .AllWRFVariables
    fi
