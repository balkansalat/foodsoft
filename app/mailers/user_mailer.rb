# -*- coding: utf-8 -*-
class UserMailer < ActionMailer::Base
  default from: "Foodsoft-Ergänzung <noreply@wohnpedia.de>"

  def user_mail(user)
    @user = user
    @minus = 3000.0
    @anteil = 5.0
    special_ordergroup_ids = Ordergroup.where(name: ['FrischeBestelldienst', 'Gast', 'Schwund', 'TrockenBestelldienst']).pluck(:id)

    sum_trans_total = FinancialTransaction.where('note LIKE \'%Bestellung%\'').sum(:amount).abs
    sum_trans_special = FinancialTransaction.where(ordergroup_id: special_ordergroup_ids).where('note LIKE \'%Bestellung%\'').sum(:amount).abs
    @sum_trans = sum_trans_total - sum_trans_special

    sum_trans_total_lager = FinancialTransaction.where('note LIKE \'%Bestellung: Lager%\'').sum(:amount).abs
    sum_trans_special_lager = FinancialTransaction.where(ordergroup_id: special_ordergroup_ids).where('note LIKE \'%Bestellung: Lager%\'').sum(:amount).abs
    @sum_trans_lager = sum_trans_total_lager - sum_trans_special_lager

    months = (Date.parse('2013-02-24') - Date.parse(@user.created_on.to_s))/30
    hours = Assignment.where(user_id: @user.id).joins(:task).sum(:duration)
#    @work = hours.to_i/months.round

    mail(to: user.email, subject: "Beißwat: Sei dabei!")
  end
end
