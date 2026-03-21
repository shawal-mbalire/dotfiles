# Carapace-bin completion configuration for Nushell

let carapace_completer = {|spans|
    # Generate builtins and functions on the fly (as carapace official does)
    load-env {
        CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq  | str join "\n")
        CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq  | str join "\n")
    }

    # if the current command is an alias, get its expansion
    let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)

    let spans = (if $expanded_alias != null {
        $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
    } else {
        $spans
    })

    carapace $spans.0 nushell ...$spans | from json
}

# Safely merge into existing config
$env.config = (
    $env.config 
    | upsert completions (
        $env.config.completions? 
        | default {} 
        | upsert external {
            enable: true
            max_results: 100
            completer: $carapace_completer
        }
    )
)
