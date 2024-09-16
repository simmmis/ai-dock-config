#!/bin/bash

# This file will be sourced in init.sh

# This file is updated by Dima

# https://raw.githubusercontent.com/ai-dock/comfyui/main/config/provisioning/default.sh

# Packages are installed after nodes so we can fix them...

DEFAULT_WORKFLOW="https://raw.githubusercontent.com/ai-dock/comfyui/main/config/workflows/flux-comfyui-example.json"

APT_PACKAGES=(
    "mc"
    "ncdu"
    #"package-1"
    #"package-2"
)

PIP_PACKAGES=(
    #"package-1"
    #"package-2"
)

NODES=(
    "https://github.com/XLabs-AI/x-flux-comfyui"
    "https://github.com/huxiuhan/ComfyUI-InstantID"
    "https://github.com/cubiq/ComfyUI_InstantID"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
    "https://github.com/WASasquatch/was-node-suite-comfyui"
    "https://github.com/EeroHeikkinen/ComfyUI-eesahesNodes"
    "https://github.com/crystian/ComfyUI-Crystools"
    "https://github.com/crystian/ComfyUI-Crystools-save"
    "https://github.com/zcfrank1st/Comfyui-Toolbox"
    "https://github.com/palant/extended-saveimage-comfyui"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/Fannovel16/comfyui_controlnet_aux"
    "https://github.com/jags111/efficiency-nodes-comfyui"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
    "https://github.com/twri/sdxl_prompt_styler"
    "https://github.com/bash-j/mikey_nodes"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/palant/extended-saveimage-comfyui"
    "https://github.com/wmatson/easy-comfy-nodes"
    "https://github.com/KoreTeknology/ComfyUI-Universal-Styler"
    "https://github.com/royceschultz/ComfyUI-Notifications"
)

CHECKPOINT_MODELS=(
)

CLIP_MODELS=(
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors"
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors"
)

UNET_MODELS=(
)

VAE_MODELS=(
)

LORA_MODELS=(
)

ESRGAN_MODELS=(
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x4.pth"
    "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth"
    "https://huggingface.co/Akumetsu971/SD_Anime_Futuristic_Armor/resolve/main/4x_NMKD-Siax_200k.pth"
)

CONTROLNET_MODELS=(
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    if [[ ! -d /opt/environments/python ]]; then 
        export MAMBA_BASE=true
    fi
    source /opt/ai-dock/etc/environment.sh
    source /opt/ai-dock/bin/venv-set.sh comfyui

    # Get licensed models if HF_TOKEN set & valid
    if provisioning_has_valid_hf_token; then
        UNET_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors")
        VAE_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors")
    else
        UNET_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors")
        VAE_MODELS+=("https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors")
        sed -i 's/flux1-dev\.safetensors/flux1-schnell.safetensors/g' /opt/ComfyUI/web/scripts/defaultGraph.js
    fi

    provisioning_print_header
    provisioning_dima_wget_list
    provisioning_get_apt_packages
    provisioning_get_default_workflow
    provisioning_get_nodes
    provisioning_get_pip_packages
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/clip" \
        "${CLIP_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    provisioning_print_end
}

function pip_install() {
    if [[ -z $MAMBA_BASE ]]; then
            "$COMFYUI_VENV_PIP" install --no-cache-dir "$@"
        else
            micromamba run -n comfyui pip install --no-cache-dir "$@"
        fi
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            pip_install ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="/opt/ComfyUI/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                   pip_install -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip_install -r "${requirements}"
            fi
        fi
    done
}

function provisioning_get_default_workflow() {
    if [[ -n $DEFAULT_WORKFLOW ]]; then
        workflow_json=$(curl -s "$DEFAULT_WORKFLOW")
        if [[ -n $workflow_json ]]; then
            echo "export const defaultGraph = $workflow_json;" > /opt/ComfyUI/web/scripts/defaultGraph.js
        fi
    fi
}

function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
    fi
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Web UI will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif 
        [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi
    if [[ -n $auth_token ]];then
        wget --header="Authorization: Bearer $auth_token" -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
}

# Downloading files what i need
function provisioning_dima_wget_list() {
    printf "Starting to Download Dima_wget_List"
    
    #CLIP vision
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/clip_vision/" "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors"
    #Xlabs-AI flux-ip-adapter
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/xlabs/ipadapters/" "https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/flux-ip-adapter.safetensors"

    # Clip (google's) Text Encoder (выше есть уже качается но удалять отсюда не буду пока)
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/clip/" "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors"

    # FLUX1 controlnets
    mkdir -p "/workspace/ComfyUI/models/xlabs/controlnets"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/xlabs/controlnets" "https://huggingface.co/XLabs-AI/flux-controlnet-collections/resolve/main/flux-depth-controlnet-v3.safetensors"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/xlabs/controlnets" "https://huggingface.co/XLabs-AI/flux-controlnet-collections/resolve/main/flux-canny-controlnet-v3.safetensors"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/xlabs/controlnets" "https://huggingface.co/XLabs-AI/flux-controlnet-collections/resolve/main/flux-hed-controlnet-v3.safetensors"
    
    #instantX controlnet
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/controlnet/" "https://huggingface.co/InstantX/FLUX.1-dev-Controlnet-Union/resolve/832dab0074e8541d4c324619e0e357befba19611/diffusion_pytorch_model.safetensors"
    mkdir -p "/workspace/ComfyUI/models/controlnet/Union-Pro/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/controlnet/Union-Pro/" "https://huggingface.co/Shakker-Labs/FLUX.1-dev-ControlNet-Union-Pro/resolve/main/diffusion_pytorch_model.safetensors"
    # переношу в ту же папку, потому что нода не увидела.
    mv "/workspace/ComfyUI/models/controlnet/Union-Pro/diffusion_pytorch_model.safetensors" "/workspace/ComfyUI/models/controlnet/diffusion_pytorch_model_PRO.safetensors"


    #FLUX1 LORAS
    mkdir -p "/workspace/ComfyUI/models/loras/"
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/745845?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/738658?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/720252?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/
    #curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/464939?type=Model&format=SafeTensor&size=full&fp=fp16" && mv $(ls -t | head -n1) ${WORKSPACE}/ComfyUI/models/loras/
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/417733?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/732180?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/804837?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/780989?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/
    curl -L -O -J -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/download/models/758624?type=Model&format=SafeTensor" && mv "$(ls -t | head -n1)" ${WORKSPACE}/ComfyUI/models/loras/

    # Докачиваем FLUX1.dev_fp8    
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/unet/" "https://huggingface.co/XLabs-AI/flux-dev-fp8/resolve/main/flux-dev-fp8.safetensors"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/unet/" "https://huggingface.co/XLabs-AI/flux-dev-fp8/resolve/main/flux_dev_quantization_map.json"
    # Вот тут еще лежат флюксы квантизованные https://huggingface.co/Kijai/flux-fp8/tree/main но я не тестил
    
    #Для InstantID файлы
    mkdir -p "/workspace/ComfyUI/models/checkpoints/sdxl/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/checkpoints/sdxl/" "https://huggingface.co/frankjoshua/albedobaseXL_v13/resolve/main/albedobaseXL_v13.safetensors"

    mkdir -p "/workspace/ComfyUI/models/instantid/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/instantid/" "https://huggingface.co/InstantX/InstantID/resolve/main/ip-adapter.bin"

    mkdir -p "/workspace/ComfyUI/models/controlnet/instantid/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/controlnet/instantid/" "https://huggingface.co/InstantX/InstantID/resolve/main/ControlNetModel/diffusion_pytorch_model.safetensors"

    #CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors
    mkdir -p "/workspace/ComfyUI/models/clip_vision/"
    wget -qnc --show-progress -O "/workspace/ComfyUI/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" "https://huggingface.co/laion/CLIP-ViT-H-14-laion2B-s32B-b79K/resolve/main/open_clip_pytorch_model.safetensors"


    #Antelopev2!!!!
    mkdir -p "/workspace/ComfyUI/models/insightface/models/antelopev2/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/insightface/models/antelopev2/" "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/1k3d68.onnx"

    mkdir -p "/workspace/ComfyUI/models/insightface/models/antelopev2/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/insightface/models/antelopev2/" "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/2d106det.onnx"

    mkdir -p "/workspace/ComfyUI/models/insightface/models/antelopev2/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/insightface/models/antelopev2/" "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/genderage.onnx"

    mkdir -p "/workspace/ComfyUI/models/insightface/models/antelopev2/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/insightface/models/antelopev2/" "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/glintr100.onnx"

    mkdir -p "/workspace/ComfyUI/models/insightface/models/antelopev2/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/insightface/models/antelopev2/" "https://huggingface.co/DIAMONIK7777/antelopev2/resolve/main/scrfd_10g_bnkps.onnx"


    mkdir -p "/workspace/ComfyUI/models/ipadapter/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/ipadapter/" "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors"

    mkdir -p "/workspace/ComfyUI/models/clip_vision/"
    wget -qnc --content-disposition --show-progress -P "/workspace/ComfyUI/models/clip_vision/" "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors"
    




###########

}  



provisioning_start




