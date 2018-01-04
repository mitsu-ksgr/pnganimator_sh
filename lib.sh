#
# Common functionality
#

#===============================================================================
#   Common Functions
#===============================================================================

#
# shell outputs
#
warn() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" 1>&2; }
err() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" 1>&2; }
die() { err "$@"; exit 1; }

#
# Logging
#
LOG_LEVEL=0 # 0:info/err, 1:verbose, 2:debug
logv() { [[ LOG_LEVEL -ge 1 ]] && echo $@; return 0; }
logd() { [[ LOG_LEVEL -ge 2 ]] && echo $@; return 0; }

#--------------------------------------
# Return highest value.
# Arguments
max() {
  local max=$1
  shift
  for n in $@ ; do
    (( n > max )) && max=$n
  done
  echo "${max}"
}

#--------------------------------------
# Make Animation GIF.
# Arguments:
#   1. targets
#   2. dst
#   3. delay
make_ani_gif() {
  convert -delay $3 \
          -loop 0 \
          -dispose previous \
          "$1" "$2"
}

#--------------------------------------
# Optimize GIF animation.
# Arguments:
#   1. target file path
optimize() {
  convert $1 -layers Optimize $1
  logd "optimize: optimized $1"
}

#--------------------------------------
# Resize & Background transparent of PNG Image.
# TODO: testing.
# Arguments:
#   1. target file path
#   3. size (length of one side)
resize() {
  convert "$1" \
      -resize "${2}x${2}" \
      -size "${2}x${2}" \
      xc:transparent +swap -gravity center -composite \
      "$1"
  logd "resize: resized $1"
}


#===============================================================================
#   Rotate Functions
#===============================================================================

#--------------------------------------
# Rotate Image
# Arguments:
#   1. src
#   2. dst
#   3. angle
#   4. extent_size
make_rotate_image() {
  local src=$1
  local dst=$2
  local angle=$3
  local extent_size=$4

  echo "make_rotate_image: angle=${angle}, extent=${extent_size}, src=${src}, dst=${dst}"

  convert -rotate "${angle}" \
          -gravity center \
          -extent "${extent_size}x${extent_size}" \
          -background none \
          "${src}" "${dst}"
  logd "make_rotate_image: ${dst} --- src=${src}"
}

#--------------------------------------
# Generate rotate animation-gif.
# Arguments:
#   1. src
#   2. dst
#   3. tmp
#   4. speed
#   5. extent_size
#   6~n. angles
_rotate() {
  local src=$1
  local dst=$2
  local tmp=$3
  local speed=$4
  local extent_size=$5
  shift 5
  local angles=($@)

  for i in ${angles[@]}; do
    make_rotate_image "${src}" "${tmp}/${i}.png" $i "${extent_size}"
  done
  make_ani_gif "${tmp}/*.png" "${dst}" "${speed}"
  logd "_rotate: generated to ${dst}"

  return 0
}

#--------------------------------------
# Generate rotate Animation GIF.
# Arguments:
#   1. src_file
#   2. dst_file_name_base
#   3. work_dir - path to temporary dir.
#   4. frames - animation frames.
#   5. delay - animation frame delay.
#   6. extent_size
#   7. optimize_flag
# Returns:
#   None
rotate() {
  local src_file=$1
  local dst_filename_base=$2
  local work_dir=$3
  local angle=`expr 360 / $4`
  local delay=$5
  local extent_size=$6
  local flag_optimize=$7

  logd "---------- RotateFunction ----------"
  logd "## Arguments"
  logd "src_file: ${src_file}"
  logd "dst_filename_base: ${dst_filename_base}"
  logd "work_dir: ${work_dir}"
  logd "frames: $4 --> angle=${angle}"
  logd "delay: ${delay}"
  logd

  # Clockwise
  mkdir "${work_dir}/cwise"
  _rotate "${src_file}" \
          "${dst_filename_base}_cwise.gif" \
          "${work_dir}/cwise" \
          "${delay}" "${extent_size}" \
          `seq -w ${angle} ${angle} 360`
  [[ "${flag_optimize}" = 'true' ]] && optimize "${dst_filename_base}_cwise.gif"

  # Counter Clockwise
  mkdir "${work_dir}/ccwise"
  _rotate "${src_file}" \
          "${dst_filename_base}_ccwise.gif" \
          "${work_dir}/ccwise" \
          "${delay}" "${extent_size}" \
          `seq -w -${angle} -${angle} -360`
  [[ "${flag_optimize}" = 'true' ]] && optimize "${dst_filename_base}_ccwise.gif"

  return 0
}
