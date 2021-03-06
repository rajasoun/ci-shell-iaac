#shellcheck shell=bash

Describe "Unit Test : " unit
    Include src/load.sh
    Context "os.sh"
        It "debug displays message when _debug_option is set"
            _debug_option -d #set debug option explicitly
            When call debug "Test Debug Message"
            The output should include "Test Debug Message"
        End
        It "debug does not displays message when _debug_option is not set"
            # _debug_option "" #unset debug option explicitly
            When call debug "Test Debug Message"
            The output should not include "Test Debug Message"
        End
        It "_debug_option -d functions to set VERBOSE=1"
            When call _debug_option -d
            The variable "$VERBOSE" should equal 1
        End
        It "all_colors function displays text in colour"
            _debug_option -d #set debug option explicitly
            When call all_colors
            The output should include "${RED}RED${NC}"
        End
        It "_display_time function with 300 returns 5 minutes and 0 seconds"
            When call _display_time 300
            The output should equal "5 minutes and 0 seconds"
        End 
        It "_display_time function with 0 returns 0 seconds"
            When call _display_time 0
            The output should equal "0 seconds"
        End
        It "_display_time function with 40000 returns 11 hours 6 minutes and 40 seconds"
            When call _display_time 40000
            The output should equal "11 hours 6 minutes and 40 seconds"
        End 
        It "_display_time function with 400000 returns 14 days 15 hours 6 minutes and 40 seconds"
            When call _display_time 400000
            The output should equal "4 days 15 hours 6 minutes and 40 seconds"
        End 
  End
End
