class ReportsController < ActionController::Base
  layout :resolve_layout

  before_action :authenticate_user!, except: [:deliver, :form_deliver]

  before_action :set_report, only: [:show, :edit, :update, :destroy, :form_deliver, :deliver, :reformulate, :approve]

  before_filter :verify_token_or_role, only: [:deliver, :form_deliver]

  # GET /reports
  # GET /reports.json
  def index
    @reports = Report.where(entregue: true, avaliacao: [nil, 'à Reformular'])
  end

  # GET /reports/1
  # GET /reports/1.json
  def show
  end

  def approve
    @report.avaliacao = "Aprovado"

    if @report.save
      mail = ReportMailer.approved_report(@report).deliver_later

      unless mail 
        redirect_to reports_path, notice: 'Ocorreu um erro ao enviar o e-mail, comunique o suporte para solucionar o problema'
      end

      redirect_to reports_path, notice: 'Relatório Aprovado com sucesso!'
    else
      redirect_to reports_path, notice: 'Ocorreu um erro ao aprovar o relatório, comunique o suporte para solucionar o problema'
    end

  end

  def reformulate
    respond_to do |format|
      @report.avaliacao = 'à Reformular'

      if @report.update(report_params)
        mail = ReportMailer.reformulate_report(@report).deliver_later

        unless mail
          redirect_to root_path, notice: 'Ocorreu um erro ao enviar o e-mail, comunique o suporte para solucionar o problema'
        end

        format.html { redirect_to reports_path, notice: 'O pedido de reformulação foi enviado com sucesso!' }
        format.json { render :show, status: :ok, location: @report }
      else
        format.html { render :edit }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  def form_deliver
  end

  def deliver
    @report.entregue = true
    respond_to do |format|
      if @report.update(report_params)

        format.html { redirect_to root_path, notice: 'O relatório foi enviado com sucesso!' }
        format.json { render :show, status: :ok, location: @report }
      else
        format.html { render :edit }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_report
    @report = Report.find(params[:id])
    @last_report = @report.project.reports.last == @report
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def report_params
    params.require(:report).permit(:data_entrega, :atividades_desenvolvidas, :resultados_obtidos, :dificuldades_encontradas, :proximas_etapas, :conclusoes, :referencias, :notificacao_antecipada, :notificacao_no_dia, :notificacao_atrasada, :project_id, :observacao_reformular)
  end

  # check if the user has access to this page or if has the token to edit this page
  def verify_token_or_role
    if (params[:access_token] == @report.access_token)
      @access_by_token = true
    else
      redirect_to root_path, notice: 'Você não tem acesso à essa página'
    end
  end
  def resolve_layout
    case action_name
    when "form_deliver"
      "report_deliver"
    else
      "application"
    end
  end
end
