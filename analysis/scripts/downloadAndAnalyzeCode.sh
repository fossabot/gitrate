#!/usr/bin/env bash

# (stdin) input format: "repository_id;repository_name;login;archive_uri;language1,language2,..."
# (stdout) output format: "repository_id;language;message_type;message"

function analyze_javascript () {
    repository_id="$1"
    repository_name="$2"
    login="$3"
    archive_output_dir="$4"

    function output () {
        language="JavaScript"
        message_type="$1"
        message="$2"
        echo "${repository_id};${language};${message_type};${message}"
    }

    valid_git_url=true
    for packagejson in $(find "${archive_output_dir}" -type f -regextype posix-extended \
        -regex '.*/(package|bower)\.json$'); do
        git_url=$(jq --monochrome-output --raw-output ".repository.url" "${packagejson}")
        if [ "${git_url}" = null ]; then
            continue
        fi
        git_url_match=$(echo "${git_url}" | grep -E "[:/]${login}/${repository_name}")
        if [ "${git_url_match}" != "${git_url}" ]; then
            valid_git_url=false
        fi
    done

    if [ "${valid_git_url}" = true ] ; then
        packagejson_dir=
        for packagejson in $(find "${archive_output_dir}" -type f -regextype posix-extended \
            -regex '.*/(package|bower)\.json$'); do
            dir=$(dirname "${packagejson}")
            if [ "${packagejson_dir}" = "" ] || [ ${packagejson_dir} = "${dir}" ]; then
                packagejson_dir="${dir}"
                for key in "dependencies" "devDependencies" ; do
                    for dep in $(jq --monochrome-output --raw-output ".${key} | keys[]" "${packagejson}"); do
                        output dependence "${dep}"
                    done
                done

                if (jq --monochrome-output --raw-output ".scripts | values[]" "${packagejson}" | grep -E "^node " || \
                    grep -RE "^#!/usr/bin/(env |)node" "${archive_output_dir}") >> /dev/null; then
                    output dependence "Node.js"
                fi
            else
                # that's probably a third-party library that was copy-pasted to the repository
                rm -r "${dir}"
            fi
            rm "${packagejson}"
        done

        if [ "${packagejson_dir}" != "" ]; then
            find "${archive_output_dir}" \
                -type f \
                -regextype posix-extended \
                -regex '.*/(\.eslint.*|yarn\.lock|.*\.min\.js|package-lock\.json|\.gitignore)$' \
                -delete

            find "${archive_output_dir}" -type f -name "*.js" -exec node "stripComments.js" "{}" ";"

            for message in $(node_modules/eslint/bin/eslint.js --format json --no-color "${archive_output_dir}" | \
                grep --extended-regexp '^\[' | \
                jq --monochrome-output --raw-output '.[].messages[] | "\(.ruleId)"'); do
                output warning "${message}"
            done

            lines_of_code=$(find "${archive_output_dir}" -type f -name "*.js" -print0 | \
                xargs -0 grep --invert-match --regexp='^\s*$' | wc -l)
            output lines_of_code "${lines_of_code}"
        fi
    fi
}

function analyze () {
    repository_id=$(echo "$1" | cut -d ";" -f1)
    repository_name=$(echo "$1" | cut -d ";" -f2)
    login=$(echo "$1" | cut -d ";" -f3)
    archive_url=$(echo "$1" | cut -d ";" -f4)
    languages=$(echo "$1" | cut -d ";" -f5)

    archive_output_dir="${current_dir}/data/${repository_id}"
    archive_path="${archive_output_dir}.tar.gz"
    wget --quiet "${archive_url}" -O "${archive_path}"
    rm -rf "${archive_output_dir}"
    mkdir -p "${archive_output_dir}"
    tar -xzf "${archive_path}" -C "${archive_output_dir}"
    rm "${archive_path}"

    good_filename_pattern="^[a-zA-Z0-9/._-]*$"
    bad_filenames=$(find "${archive_output_dir}" -type f | \
        sed "s!.*${repository_id}!!" | \
        grep --count --invert-match --extended-regexp "${good_filename_pattern}")

    if [ "${bad_filenames}" -eq 0 ]; then
        for language in $(echo "${languages}" | tr "," "\\n"); do
            if [[ "${language}" = JavaScript ]]; then
                analyze_javascript "${repository_id}" "${repository_name}" "${login}" "${archive_output_dir}"
            fi
        done
    fi

    if [ "${cleanup}" = true ]; then
        rm -r "${archive_output_dir}"
    fi
}

current_dir=$(dirname "$0")
cd "${current_dir}" || exit 1

cleanup=false
while true; do
  case "$1" in
    --with-cleanup ) cleanup=true; shift ;;
    * ) break ;;
  esac
done

# redirect stderr to null
exec 2>/dev/null

while read -r line; do
    analyze "${line}"
done
