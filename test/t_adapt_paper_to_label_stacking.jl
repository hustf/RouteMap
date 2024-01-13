# Experiment: How small can the "printed page" be, given that all labels must show?`
# The label size is unchanged here, because the result needs to be readable.
# But changing the font size is of course another way to do it, respecting readability in
# prints.

@test abs(find_boolean_step_using_interval_halving(;lower = 1.0, upper = 10.0, iterations = 100) do x
    x >= π
end - 3.1415) < 1e-3

# Testing is currently done with more realistic route map size in the environment 'Marey'
