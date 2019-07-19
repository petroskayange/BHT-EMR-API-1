class ProgramPatientsService

  ENGINES = {
    'ANC PROGRAM' => ANCService::PatientsEngine,
    'HIV PROGRAM' => ARTService::PatientsEngine,
    'HTC PROGRAM' => HTSService::PatientsEngine,
    'OPD PROGRAM' => OPDService::PatientsEngine,
    'TB PROGRAM' => TBService::PatientsEngine
  }.freeze

  attr_reader :program

  def initialize(program:)
    @program = program
    clazz = ENGINES[program.name.upcase]
    @engine = clazz.new(program: program)
  end

  def patients
    Patient.joins(:patient_programs)\
           .where(patient_program: { program_id: program.id })
  end

  def method_missing(method, *args, &block)
    Rails.logger.debug "Executing missing method: #{method}"
    return @engine.send(method, *args, &block) if respond_to_missing?(method)

    super(method, *args, &block)
  end

  def respond_to_missing?(method)
    Rails.logger.debug "Engine responds to #{method}? #{@engine.respond_to?(method)}"
    @engine.respond_to?(method)
  end
end
