alias yolo='claude --dangerously-skip-permissions'

function c
    if test (count $argv) -gt 0 -a "$argv[1]" = "yolo"
        codex --yolo $argv[2..]
    else
        codex $argv
    end
end
