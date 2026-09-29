#!/bin/bash

# module load nvidia-hpc-sdk/26.5
# module load python/3.14.7-gcc

CONFIG_FILE="config.json"

jq -c '.configurations[]' "$CONFIG_FILE" | while read -r config; do

    FI=$(echo "$config" | jq -r '.fi')
    FI_RANK=$(echo "$config" | jq -r '.fi_rank')
    SNAP=$(echo "$config" | jq -r '.snap')
    TAG=$(echo "$config" | jq -r '.tag')
    KERNEL=$(echo "$config" | jq -r '.kernel')
    SCATTER=$(echo "$config" | jq -r '.scatter')
    THR=$(echo "$config" | jq -r '.thr')
    REPROJECT_BC=$(echo "$config" | jq -r '."reproject-bc"')
    DETECT=$(echo "$config" | jq -r '.detect')
    VERIFY=$(echo "$config" | jq -r '.verify')
    NO_SOURCE=$(echo "$config" | jq -r '.no_source')
    IC=$(echo "$config" | jq -r '.ic')
    DUMP_SNAPS=$(echo "$config" | jq -r '.dump_snaps')
    DIAG_CG=$(echo "$config" | jq -r '.diag_cg')
    QRANK=$(echo "$config" | jq -r '.qrank')
    QBLOCK=$(echo "$config" | jq -r '.qblock')

    NSYS_ARGS=(
        -t cuda,nvtx
        --cuda-memory-usage=true
        -f true
        -o first_prof
    )


    APP_ARGS=()

    read -r FI_LEVEL FI_STEP FI_TARGET FI_BIT <<< "$FI"

    APP_ARGS+=(
        --fi
        "$FI_LEVEL"
        "$FI_STEP"
        "$FI_TARGET"
        "$FI_BIT"
    )

    APP_ARGS+=(
        --fi-rank "$FI_RANK"
        --snap "$SNAP"
        --tag "$TAG"
        --kernel "$KERNEL"
        --scatter "$SCATTER"
        --thr "$THR"
    )


    [[ "$REPROJECT_BC" == "true" ]] && APP_ARGS+=(--reproject-bc)
    [[ "$DETECT"      == "true" ]] && APP_ARGS+=(--detect)
    [[ "$VERIFY"      == "true" ]] && APP_ARGS+=(--verify)
    [[ "$NO_SOURCE"   == "true" ]] && APP_ARGS+=(--no-source)

    APP_ARGS+=(
        --ic "$IC"
    )

    [[ "$DUMP_SNAPS" == "true" ]] && APP_ARGS+=(--dump-snaps)

    APP_ARGS+=(
        --diag-cg "$DIAG_CG"
    )

    [[ "$QRANK" == "true" ]] && APP_ARGS+=(--qrank)

    read -r QBLOCK_X QBLOCK_Y QBLOCK_Z QBLOCK_M <<< "$QBLOCK"

    APP_ARGS+=(
        --qblock
        "$QBLOCK_X"
        "$QBLOCK_Y"
        "$QBLOCK_Z"
        "$QBLOCK_M"
    )

    echo "Executing configuration: $TAG"

    printf 'nsys profile '
    printf '%q ' "${NSYS_ARGS[@]}"
    printf 'mpirun -np 1 ./build/heat_solver_het '
    printf '%q ' "${APP_ARGS[@]}"
    printf '\n'

    nsys profile \
            "${NSYS_ARGS[@]}" \
            mpirun -np 1 \
            ./build/heat_solver_het \
            "${APP_ARGS[@]}"

done