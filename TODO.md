# TODO

## OrderLive: кнопка Count
- [x] Проверить, от чего зависит рендер кнопки Count (can_count_post_cost?)
- [x] Подтвердить бизнес-условия в `Calculation.can_count_post_cost?/2` (customer.city.pindex непустой)
- [x] Добавить тест, который проверяет появление кнопки Count в `test/jersey_web/live/order_live/form_count_test.exs`
- [ ] При необходимости поправить логику пересчёта can_count при изменениях customer/order_items
- [ ] Прогнать `mix test test/jersey_web/live/order_live/form_test.exs` и весь `mix test`

