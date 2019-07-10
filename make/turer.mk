.PHONY: _ignore_this

_ignore_this:


##### Generic helpers.

# Invert a value.
not = $(if $(strip $(1)),,1)

# A literal comma.
comma := ,


##### String helpers.

# For each character in $(1), call $(2) with two arguments: the given character, and the input
# string. Then, the input string is assigned to the result of the call, and this is repeated.
# And the end, returns the resulting string.
_build_call_for_each_char_impl = \
	$(eval _helper := $$(3)) \
	$(foreach _char,$(1),$(eval _helper := $$(call $(2),$$(_char),$$(_helper)))) \
	$(_helper)
build_call_for_each_char = $(strip $(call _build_call_for_each_char_impl,$(1),$(2),$(3)))

# For each character in $(1), prepend a space to every occurence of it in $(2).
# Example: $(call prepend_space,a b,abcd) -> " a bcd"
_prepend_space_impl = $(subst $(1), $(1), $(2))
prepend_space = $(call build_call_for_each_char,$(1),_prepend_space_impl,$(2))

# For each character in $(1), replace each word in $(2) starting with said character with just
# that character.
# Example: $(call keep_first_char,a b,ax by cz) -> "a b cz"
_keep_first_char_impl = $(patsubst $(1)%,$(1),$(2))
keep_first_char = $(call build_call_for_each_char,$(1),_keep_first_char_impl,$(2))


##### Numeric helpers.

# Numbers are represented as a series of x's of length N, e.g. 3 is "x x x". We can get the
# true numeric value of any of these by calling $(words) on it.
# Any empty variable can be seen as 0.

include number-values.mk

one := $(value_1)

# Example: $(call inc,x x) -> "x x x"
inc = $(1) x
# Example: $(call dec,x x x) -> "x x"
dec = $(wordlist 2,$(words $(1)),$(1))

# Converts a decimal value (e.g. 4) to a series of x's (e.g. "x x x x").
value_to_words = $(value_$(1))


##### I/O

# Unfortunately, the ONLY shell usage in this file, as I couldn't figure out any way to do pure
# make I/O without adding newlines (including using $(file ...)).

# Print a character directly to stdout.
# Example: $(call print_char,$(value_65)) -> prints "A"
# Note that this takes a words-based number (a series of x's), not a decimal value.
# We print to stderr to avoid make capturing the output.
print_char_words = $(shell >&2 printf \\$$(printf '%o' $(words $(1))))

# Reads a single character value from stdin.
# Note that this returns a words-based number (a series of x's), not a decimal value.
read_char_words = $(call value_to_words,$(shell read -N1 value && printf %d "'$$value"))


##### Program initialization.

program := $(file < $(FILE))

commands := + - [ ] < > . ,

# Prepend a space to each special character.
program := $(call prepend_space,$(commands),$(program))
# Strip any comments from the end of a command character.
program := $(call keep_first_char,$(commands),$(program))
# # Remove any leftover comments.
program := $(filter $(commands),$(program))

# Now our program is an easy-to-adapt format. Start setting up our execution environment.
# The tape is represented as a set of variables tape_NUMBER, e.g. tape_1, tape_2, etc.

tape_location := $(one)
program_location := $(one)

tape_location_value = $(words $(tape_location))
program_location_value = $(words $(program_location))


##### Evaluator helpers and functions.

# Get the current command character.
current_cmd = $(word $(program_location_value),$(program))

# Move to the next program location.
program_next = $(eval program_location := $$(call inc,$$(program_location)))
# Move to the previous program location.
program_prev = $(eval program_location := $$(call dec,$$(program_location)))

# Example:
#  $(call match_lbr_or_rbr,[,x x,inc,dec) -> "x x x"
#  $(call match_lbr_or_rbr,],x x,inc,dec) -> "x"
#  $(call match_lbr_or_rbr,+,x x,inc,dec) -> "x x"
match_lbr_or_rbr = $(if $(findstring [,$(1)),$(call $(3),$(2)),\
						$(if $(findstring ],$(1)),$(call $(4),$(2)),$(2)))

# We need to track nested to make sure we grab the right bracket.
_jump_to_next_right_bracket_impl = $(if $(call not,$(1)),\
									,\
									$(call program_next)\
									$(call _jump_to_next_right_bracket_impl,\
										$(call match_lbr_or_rbr,$(call current_cmd),$(1),\
											inc,dec)))
jump_to_next_right_bracket = $(call _jump_to_next_right_bracket_impl,$(one))

_jump_to_prev_left_bracket_impl = $(if $(call not,$(1)),\
									,\
									$(call program_prev)\
									$(call _jump_to_prev_left_bracket_impl,\
										$(call match_lbr_or_rbr,$(call current_cmd),$(1),\
											dec,inc)))
jump_to_prev_left_bracket = $(call _jump_to_prev_left_bracket_impl,$(one))

eval_add = $(eval tape_$$(tape_location_value) := $$(call inc,$$(tape_$$(tape_location_value))))
eval_sub = $(eval tape_$$(tape_location_value) := $$(call dec,$$(tape_$$(tape_location_value))))
eval_lmv = $(eval tape_location := $$(call dec,$$(tape_location)))
eval_rmv = $(eval tape_location := $$(call inc,$$(tape_location)))
eval_lbr = $(if $(call not,$(tape_$(tape_location_value))),$(call jump_to_next_right_bracket),)
eval_rbr = $(if $(tape_$(tape_location_value)),$(call jump_to_prev_left_bracket),)
eval_print = $(call print_char_words,$(tape_$(tape_location_value)))
eval_read = $(eval tape_$$(tape_location_value) := $$(call read_char_words))
# This shouldn't be necessary but ¯\_(ツ)_/¯
eval_none =
# Find the name of the function to use to evaluate the command $(1).
find_eval_function = $(if $(findstring +,$(1)),eval_add,\
						$(if $(findstring -,$(1)),eval_sub,\
							$(if $(findstring <,$(1)),eval_lmv,\
								$(if $(findstring >,$(1)),eval_rmv,\
									$(if $(findstring [,$(1)),eval_lbr,\
										$(if $(findstring ],$(1)),eval_rbr,\
											$(if $(findstring .,$(1)),eval_print,\
												$(if $(findstring $(comma),$(1)),eval_read,\
													eval_none))))))))

evaluate_cmd = $(call $(call find_eval_function,$(1)))

evaluate = \
	$(call evaluate_cmd,$(call current_cmd)) \
	$(call program_next) \
	$(if $(call current_cmd),$(call evaluate),)  # Recurse back into evaluate

$(call evaluate)
