function confirm
  read --prompt-str "$argv[1] [Y/n] " --local answer
  or return 1
  not string match --quiet --regex --ignore-case '^n' -- $answer
end
funcsave confirm
