# frozen_string_literal: true

##
# Dynamically retrieve service engines from program service modules.
#
# Examples:
# =========
#   1. We have a PatientsEngine in '/app/services/anc_service/patients_engine.rb.
#      To load the engine we do the following:
#
#   >>> clazz = ProgramEngineLoader.load(Program.find_by_name('ANC Program'), 'patients')
#   >>> patients_service = clazz.new(patient: Patient.first)
#   >>> patients_service.print_visit_summary
#
# Registration of program service modules
# =======================================
# A program has to be created in the programs table with a name having the following
# format /(?<name>[A-Z]+[A-Z0-9]*) Program/. Then create a directory `in app/services/``
# named in the format /(?<name>[a-z]+[a-z0-9]*)_service/. NOTE: The case of the names
# matters. Program names must be an uppercase word follow by 'Program' and the directory
# must be all lowercase.
#
# For example: to add a TB service module, first a new program is to be created in the
# database with the name `TB Program` then a directory is created in `app/services/`
# with the name `tb_service`.
#
# Adding an engine to a program service module
# ============================================
# An engine must be either a class or a plain old ruby module. It must be named in
# the following format:
#
#   /(?<program_name>[A-Z]+[A-Z0-9]*)Service::(?<engine_name>[A-Z]{1}[a-z0-9]+)Engine/
#
# Continuing with the example from the previous section, a patients engine for the
# TB service wouldd be defined as follows:
#
#   # app/services/tb_service/patients_engine.rb
#
#   module TBService::PatientsEngine
#      # ...
#   end
module ProgramEngineLoader
  class << self
    PROGRAM_NAMESPACES = {
      Program.find_by_name('HIV Program').id => 'ARTService'
    }.freeze

    def load(program, engine_name)
      "#{program_namespace(program)}::#{engine_class_name(engine_name)}".constantize
    end

    private

    def program_namespace(program)
      return PROGRAM_NAMESPACES[program.id] if PROGRAM_NAMESPACES.include?(program.id)

      "#{program.name.gsub(/\s+program$/i, '').upcase}Service"
    end

    def engine_class_name(name)
      "#{name.capitalize}Engine"
    end
  end
end
