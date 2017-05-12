class TasksController < ApplicationController
  before_action :prepare_tasks

  def index
  end

  def create
    @task = Task.new(task_params)
    @task.save
    render :create
  end

  private

  def task_params
    params.require(:task).permit(:title, :content)
  end

  def prepare_tasks
    @tasks = Task.last(10)
  end
end
