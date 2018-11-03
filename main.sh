#!/bin/bash
INTERNAL_DIR=$(dirname "$BASH_SOURCE")
if [ -f ~/.config/DeepFaceLab/workspace.conf ]; then
  WORKSPACE=$(cat ~/.config/DeepFaceLab/workspace.conf)
  WORKSPACE_ROOT=$(realpath "$WORKSPACE/..")
else
  WORKSPACE_ROOT=$INTERNAL_DIR/workspace
  WORKSPACE=$WORKSPACE_ROOT/default
fi
PYTHON=`which python`

WORKSPACE_SELECTED=""
workspace_select(){
        WORKSPACE_SELECTED=""
        readarray -t PROJECT_LIST < <(find $WORKSPACE_ROOT -mindepth 1 -maxdepth 1 -type d -printf '%P\n')
        PROJECT_LIST+=("custom input")
        PROJECT_LIST+=("DeepFaceLab default")
        PROJECT_LIST+=("cancel selection")
        select PROJECT in "${PROJECT_LIST[@]}"
        do
          case $PROJECT in
            "DeepFaceLab default" )
              WORKSPACE_SELECTED=$INTERNAL_DIR/workspace
              break
              ;;
            "custom input" )
              echo -n "Custom workspace directory: "; read WORKSPACE_SELECTED
              break
              ;;
            "cancel selection" )
              WORKSPACE_SELECTED=$WORKSPACE
              break
              ;;
            *)
              if [ -z "$PROJECT" ]; then
                echo "Invalid choice!"
              else
                WORKSPACE_SELECTED=$WORKSPACE_ROOT/$PROJECT
              fi
              break
              ;;
          esac
        done
}

PS3="Please enter your choice: "
options=("set workspace" "clear workspace" "import data_src via hard-links" "import data_dst via hard-links" "import model via copy" "clear workspace" "extract PNG from video data_src" "data_src extract faces" "data_src sort" "extract PNG from video data_dst" "data_dst extract faces" "data_dst sort by hist" "train" "convert" "converted to mp4" "quit")
select opt in "${options[@]}"
do
        case $opt in
                "set workspace" )
                        WORKSPACE_NEW="n"
                        WORKSPACE_PREV="$WORKSPACE"
                        echo "Current workspace is $WORKSPACE"
                        if [ ! -z "$WORKSPACE_ROOT" ]; then
                                echo "Please select the new workspace:"
                                workspace_select
                        fi

                        if [ ! -z "$WORKSPACE_SELECTED" ]; then
                                WORKSPACE="$WORKSPACE_SELECTED"
                                if [ ! -d $WORKSPACE ]; then
                                  WORKSPACE_NEW="y"
                                fi
                                mkdir -p $WORKSPACE
                                mkdir -p $WORKSPACE/data_src/aligned
                                mkdir -p $WORKSPACE/data_dst/aligned
                                mkdir -p $WORKSPACE/model
                                mkdir -p ~/.config/DeepFaceLab
                                WORKSPACE=`realpath $WORKSPACE`
                                echo "$WORKSPACE" > ~/.config/DeepFaceLab/workspace.conf
                                echo "New workspace is ${WORKSPACE}"
                        fi
                        ;;
                "import model via copy" )
                        echo "Please select the workspace to copy from:"
                        workspace_select
                        workspace_clone_model="n"
                        echo -n "Warning! The current model will be deleted! Continue? [y/N] "; read workspace_clone_model
                        if [ "$workspace_clone_model" == "Y" ] || [ "$workspace_clone_model" == "y" ]; then
                                echo "Copying ${WORKSPACE_SELECTED}/model into ${WORKSPACE}/model ..."
                                rm $WORKSPACE/model/*
                                cp -p $WORKSPACE_SELECTED/model/* $WORKSPACE/model/ && echo "Success!"
                        fi
                        ;;
                "import data_src via hard-links" )
                        echo "Please select the workspace to link from:"
                        workspace_select
                        workspace_clone_source="n"
                        echo -n "Warning! The current data_src content will be deleted! Continue? [y/N] "; read workspace_clone_source
                        if [ "$workspace_clone_source" == "Y" ] || [ "$workspace_clone_source" == "y" ]; then
                                echo "Linking ${WORKSPACE_SELECTED}/data_src into ${WORKSPACE}/data_src ..."
                                rm $WORKSPACE/data_src/*.*
                                ln -P $WORKSPACE_SELECTED/data_src/*.* $WORKSPACE/data_src/ && echo "Success!"
                                echo "Linking ${WORKSPACE_SELECTED}/data_src/aligned into ${WORKSPACE}/data_src/aligned ..."
                                rm $WORKSPACE/data_src/aligned/*.*
                                ln -P $WORKSPACE_SELECTED/data_src/aligned/*.* $WORKSPACE/data_src/aligned/ && echo "Success!"
                        fi
                        ;;
                "import data_dst via hard-links" )
                        echo "Please select the workspace to link from:"
                        workspace_select
                        workspace_clone_dest="n"
                        echo -n "Warning! The current data_dst content will be deleted! Continue? [y/N] "; read workspace_clone_dest
                        if [ "$workspace_clone_dest" == "Y" ] || [ "$workspace_clone_dest" == "y" ]; then
                                echo "Linking ${WORKSPACE_SELECTED}/data_dst into ${WORKSPACE}/data_dst ..."
                                rm $WORKSPACE/data_dst/*.*
                                ln -P $WORKSPACE_SELECTED/data_dst/*.* $WORKSPACE/data_dst/ && echo "Success!"
                                echo "Linking ${WORKSPACE_SELECTED}/data_dst/aligned into ${WORKSPACE}/data_dst/aligned ..."
                                rm $WORKSPACE/data_dst/aligned/*.*
                                ln -P $WORKSPACE_SELECTED/data_dst/aligned/*.* $WORKSPACE/data_dst/aligned/ && echo "Success!"
                        fi
                        ;;
                "clear workspace" )
                        echo -n "Clean up workspace? [Y/n] "; read workspace_ans
                        if [ "$workspace_ans" == "Y" ] || [ "$workspace_ans" == "y" ]; then
                                rm -rf $WORKSPACE
                                mkdir -p $WORKSPACE/data_src/aligned
                                mkdir -p $WORKSPACE/data_dst/aligned
                                mkdir -p $WORKSPACE/model
                                echo "Workspace has been successfully cleaned!"
                        fi
                        ;;
                "extract PNG from video data_src" )
                        echo -n "File name: "; read filename
                        echo -n "FPS: "; read fps
                        if [ -z "$fps" ]; then fps="25"; fi
                        ffmpeg -i $WORKSPACE/$filename -r $fps $WORKSPACE/data_src/%04d.png -loglevel error
                        ;;
                "data_src extract faces" )
                        echo -n "Detector? [dlib | mt | manual] "; read detector
                        echo -n "Multi-GPU? [Y/n] "; read gpu_ans
                        if [ "$gpu_ans" == "Y" ] || [ "$gpu_ans" == "y" ]; then gpu_ans="--multi-gpu"; else gpu_ans=""; fi
                        $PYTHON $INTERNAL_DIR/main.py extract --input-dir $WORKSPACE/data_src --output-dir $WORKSPACE/data_src/aligned --detector $detector $gpu_ans --debug
                        ;;
                "data_src sort" )
                        echo -n "Sort by? [blur | brightness | face-yaw | hue | hist | hist-blur | hist-dissim] "; read sort_method
                        $PYTHON $INTERNAL_DIR/main.py sort --input-dir $WORKSPACE/data_src/aligned --by $sort_method
                        ;;
                "extract PNG from video data_dst" )
                        echo -n "File name: "; read filename
                        echo -n "FPS: "; read fps
                        if [ -z "$fps" ]; then fps="25"; fi
                        ffmpeg -i $WORKSPACE/$filename -r $fps $WORKSPACE/data_dst/%04d.png -loglevel error
                        ;;
                "data_dst extract faces" )
                        echo -n "Detector? [dlib | mt | manual] "; read detector
                        echo -n "Multi-GPU? [Y/n] "; read gpu_ans
                        if [ "$gpu_ans" == "Y" ] || [ "$gpu_ans" == "y" ]; then gpu_ans="--multi-gpu"; else gpu_ans=""; fi
                        $PYTHON $INTERNAL_DIR/main.py extract --input-dir $WORKSPACE/data_dst --output-dir $WORKSPACE/data_dst/aligned --detector $detector $gpu_ans --debug
                        ;;
                "data_dst sort by hist" )
                        $PYTHON $INTERNAL_DIR/main.py sort --input-dir $WORKSPACE/data_dst/aligned --by hist
                        ;;
                "train" )
                        echo -n "Model? [ H64 (2GB+) | H128 (3GB+) | DF (5GB+) | LIAEF128 (5GB+) | LIAEF128YAW (5GB+) | MIAEF128 (5GB+) | AVATAR (4GB+) ] "; read model
                        echo -n "Multi-GPU? [Y/n] "; read gpu_ans
                        echo -n "Batch size? [8] "; read batch_size
                        if [ "$gpu_ans" == "Y" ] || [ "$gpu_ans" == "y" ]; then gpu_ans="--multi-gpu"; else gpu_ans=""; fi
                        if [ -z "$batch_size" ]; then batch_size="8"; fi
                        $PYTHON $INTERNAL_DIR/main.py train --training-data-src-dir $WORKSPACE/data_src/aligned --training-data-dst-dir $WORKSPACE/data_dst/aligned --model-dir $WORKSPACE/model --model $model --batch-size $batch_size $gpu_ans
                        ;;
                "convert" )
                        echo -n "Model? [ H64 (2GB+) | H128 (3GB+) | DF (5GB+) | LIAEF128 (5GB+) | LIAEF128YAW (5GB+) | MIAEF128 (5GB+) | AVATAR(4GB+) ] "; read model
                        $PYTHON $INTERNAL_DIR/main.py convert --input-dir $WORKSPACE/data_dst --output-dir $WORKSPACE/data_dst/merged --aligned-dir $WORKSPACE/data_dst/aligned --model-dir $WORKSPACE/model --model $model --ask-for-params
                        ;;
                "converted to mp4" )
                        echo -n "File name of destination video: "; read filename
                        echo -n "FPS: "; read fps
                        if [ -z "$fps" ]; then fps="25"; fi
                        ffmpeg -y -i $WORKSPACE/$filename -r $fps -i "$WORKSPACE/data_dst/merged/%04d.png" -map 0:a? -map 1:v -r $fps -c:v libx264 -b:v 8M -pix_fmt yuv420p -c:a aac -b:a 192k -ar 48000 "$WORKSPACE/result.mp4" -loglevel error
                        ;;
                "quit" )
                        break
                        ;;
                *)
                        echo "Invalid choice!"
                        ;;
        esac
done
