#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область СлужебныйПрограммныйИнтерфейс

// Функция определяет, что обработка является обработкой доставки оповещений.
// 
// Возвращаемое значение:
//   Булево
// 
Функция ЭтоОбработкаДоставкиОповещений() Экспорт
	
	Возврат Истина;
	
КонецФункции

// Функция возвращает настройки доставки по умолчанию.
// 
// Возвращаемое значение:
//   РезСтруктура   - Структура
// 
Функция НастройкиПоУмолчанию() Экспорт

	РезСтруктура = Новый Структура;
	Возврат РезСтруктура;
	
КонецФункции

// Процедура выполняет отправку сообщений;
// 
// Параметры:
//  СообщениеСтруктура  - Структура.
//  НастройкиДоставки   - Структура.
//  СтруктураПараметров - Структура.
//  ПротоколОтправки    - Строка.
// 
Функция ОтправитьСообщение(СообщениеСтруктура, НастройкиДоставки, СтруктураПараметров, ПротоколОтправки="") Экспорт
	
	ДействиеВыполнено = Ложь;			
	Отказ             = Ложь;
	
	// Выполним проверки настроек 
	СтруктураСообщенияКорректна(СообщениеСтруктура, Отказ, ПротоколОтправки);	
	СтруктураПараметровКорректна(СтруктураПараметров, Отказ, ПротоколОтправки); 
	
	Если НЕ Отказ Тогда
		Если СтруктураПараметров.АдресПолучателя.ПометкаУдаления Тогда
			Отказ = Истина;
		КонецЕсли;
	КонецЕсли;
	
	Если НЕ Отказ Тогда
		
		МобильноеУстройство = СтруктураПараметров.АдресПолучателя;

		ТокенДоступа = ТокенДоступа(Отказ, ПротоколОтправки);
		Если Отказ Тогда
			ДействиеВыполнено = Ложь;
			Возврат ДействиеВыполнено;	
		КонецЕсли;
		Авторизация = СтрШаблон("Bearer %1", ТокенДоступа);
		
		Заголовки = Новый Соответствие;
		Заголовки.Вставить("Content-Type","application/json"); 
		Заголовки.Вставить("Authorization",Авторизация);
		
		Если ЗначениеЗаполнено(СообщениеСтруктура.Бейджи) Тогда
			Бейдж = СообщениеСтруктура.Бейджи;
		Иначе
			Бейдж = 0;
		КонецЕсли;
		
		ШаблонЗапроса = "{
						|  ""message"": {
						|    ""token"":""%1"",
						|    ""notification"": {
						|      ""title"": ""%2"",
						|      ""body"": ""%3""
						|    }
						|  }
						|}";
		СообщениеЗаголовок = СтрЗаменить(СообщениеСтруктура.Заголовок, """", "\""");
		СообщениеТекст     = СтрЗаменить(СообщениеСтруктура.Текст, """", "\""");
		ТелоЗапроса        = СтрШаблон(ШаблонЗапроса,  МобильноеУстройство.Токен, СообщениеЗаголовок, СообщениеТекст);
		
		// Отправка оповещения
		ЗащищенноеСоединение = ОбщегоНазначенияКлиентСервер.НовоеЗащищенноеСоединение();
		Соединение           = Новый HTTPСоединение("fcm.googleapis.com",,,,, 30, ЗащищенноеСоединение);
		Запрос               = Новый HTTPЗапрос;
		Запрос.АдресРесурса  = "v1/projects/bitfinance-grotem/messages:send";
		Запрос.Заголовки     = Заголовки;
		Запрос.УстановитьТелоИзСтроки(ТелоЗапроса, КодировкаТекста.UTF8);
		
		СтруктураОтвета = Соединение.ОтправитьДляОбработки(Запрос);
		ТелоОтвета = СтруктураОтвета.ПолучитьТелоКакСтроку();
		                                                                                          
		Если СтруктураОтвета.КодСостояния = 200 Тогда
			
			Если (СтрНайти(ТелоОтвета, "InvalidRegistration") > 0) ИЛИ (СтрНайти(ТелоОтвета, "NotRegistered") > 0) Тогда
				МобильноеУстройствоОб = МобильноеУстройство.ПолучитьОбъект();
				МобильноеУстройствоОб.ПометкаУдаления = Истина;
				ЗаписьПометки = бит_ОбщегоНазначения.ЗаписатьСправочник(МобильноеУстройствоОб,"","Ошибки",Истина);
			КонецЕсли;			
			
			ДействиеВыполнено = Истина;			
			ПротоколОтправки  = НСтр("ru='Сообщение отправлено на мобильное устройство. Сообщение: %1. Ответ сервера: %2.';
									|en='Message sent to the mobile device. Message: %1. Server response: %2.'");
			ПротоколОтправки  = СтрШаблон(ПротоколОтправки, ТелоЗапроса, ТелоОтвета);			
			
		Иначе	
			
			ПротоколОтправки  = НСтр("ru='Ошибка отправки сообщения на мобильное устройство. Сообщение: %1. Ответ сервера: %2.';
									|en='Error sending a message to a mobile device. Message: %1. Server response: %2.'");
			ПротоколОтправки  = СтрШаблон(ПротоколОтправки, ТелоЗапроса, ТелоОтвета);						
			ДействиеВыполнено = Ложь;
			
		КонецЕсли; 
		
	КонецЕсли;
		
	Возврат ДействиеВыполнено;
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Процедура проверяет корретность структуры сообщения.
// 
Процедура СтруктураСообщенияКорректна(Сообщение, Отказ, ПротоколОтправки = "")
	
	// Приведем строковое описание типа текста к системному перечислению.
	Если НЕ Сообщение.Свойство("ТипТекстаСообщения")
		ИЛИ НЕ ЗначениеЗаполнено(Сообщение.ТипТекстаСообщения) Тогда
		
		ТипТекстаСообщения = ТипТекстаПочтовогоСообщения.ПростойТекст;
	Иначе
		
		Для Каждого ТекущийТипТекста Из ТипТекстаПочтовогоСообщения Цикл
			
			Если Строка(ТекущийТипТекста) = Сообщение.ТипТекстаСообщения Тогда
				ТипТекстаСообщения = ТекущийТипТекста;
				
				Прервать;
			КонецЕсли;
			
		КонецЦикла;
		
	КонецЕсли;
	
	Сообщение.Вставить("ТипТекстаСообщения", ТипТекстаСообщения);
	
КонецПроцедуры

// Процедура проверяет корретность структуры параметров.
// 
Процедура СтруктураПараметровКорректна(Настройка, Отказ, ПротоколОтправки = "")
	
	Если НЕ Настройка.Свойство("АдресПолучателя") ИЛИ НЕ ЗначениеЗаполнено(Настройка.АдресПолучателя) Тогда	
		Отказ = Истина;
		ПротоколОтправки = НСтр("ru = 'Не указано мобильное устройство получателя.'; 
							    |en = 'The recipient’s mobile device is not specified.'");				
	КонецЕсли; 

КонецПроцедуры

Функция ТокенДоступа(Отказ, ПротоколОтправки)

	ДанныеПредъявителя = ОбщегоНазначения.ХранилищеОбщихНастроекЗагрузить(
		"НастройкиДоставкиОповещенийPush", "ДанныеПредъявителя");
	
	Если ДанныеПредъявителя <> Неопределено Тогда
		ДатаСравнения = ТекущаяУниверсальнаяДата() + 120;
		Если ДатаСравнения < ДанныеПредъявителя.СрокДействия Тогда
			Возврат ДанныеПредъявителя.ТокенДоступа;
		КонецЕсли;
	КонецЕсли;

	Заголовки = Новый Соответствие;
	Заголовки.Вставить("Content-Type", "application/json");

	Предъявитель = Предъявитель();
	ШаблонЗапроса = "{
	                |  ""grant_type"":""urn:ietf:params:oauth:grant-type:jwt-bearer"",
	                |  ""assertion"":""%1""
	                |}";
	ТелоЗапроса = СтрШаблон(ШаблонЗапроса, Предъявитель);
	
	ЗащищенноеСоединение = ОбщегоНазначенияКлиентСервер.НовоеЗащищенноеСоединение();
	Соединение           = Новый HTTPСоединение("oauth2.googleapis.com",,,,, 30, ЗащищенноеСоединение);
	Запрос               = Новый HTTPЗапрос;
	Запрос.АдресРесурса  = "token";
	Запрос.Заголовки     = Заголовки;
	Запрос.УстановитьТелоИзСтроки(ТелоЗапроса);
	
	СтруктураОтвета = Соединение.ОтправитьДляОбработки(Запрос);
	ТелоОтвета = СтруктураОтвета.ПолучитьТелоКакСтроку();

	Если СтруктураОтвета.КодСостояния = 200 Тогда

		ЧтениеJSON = Новый ЧтениеJSON;
		ЧтениеJSON.УстановитьСтроку(ТелоОтвета);
		ТелоОтвета = ПрочитатьJSON(ЧтениеJSON);
		ЧтениеJSON.Закрыть();

		ТокенДоступа = ТелоОтвета.access_token;
		ДанныеПредъявителя = Новый Структура;
		ДанныеПредъявителя.Вставить("СрокДействия", ТекущаяУниверсальнаяДата() + 3600);
		ДанныеПредъявителя.Вставить("ТокенДоступа", ТокенДоступа);
		ОбщегоНазначения.ХранилищеОбщихНастроекСохранить("НастройкиДоставкиОповещенийPush", "ДанныеПредъявителя", ДанныеПредъявителя);
	Иначе
		ПротоколОтправки = НСтр("ru = 'Ошибка получения токена доступа для отправки сообщения на мобильное устройство. Сообщение: %1. Ответ сервера: %2.';
		                        |en = 'Error getting access token to send message to mobile device. Message: %1. Server response: %2.'");
		ПротоколОтправки = СтрШаблон(ПротоколОтправки, ТелоЗапроса, ТелоОтвета);						
		Отказ            = Истина;
		ТокенДоступа     = "";
	КонецЕсли; 
	
	Возврат ТокенДоступа;
	
КонецФункции

Функция Предъявитель()

	ОписаниеКлюча =
	"ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAi
	|Yml0ZmluYW5jZS1ncm90ZW0iLAogICJwcml2YXRlX2tleV9pZCI6ICI0ZmFlNTY5
	|YjNmYTM0NTcxMmExZDc0YmFlMjQ2ZmVkZjhjOWUxMDE1IiwKICAicHJpdmF0ZV9r
	|ZXkiOiAiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUlFdkFJQkFEQU5C
	|Z2txaGtpRzl3MEJBUUVGQUFTQ0JLWXdnZ1NpQWdFQUFvSUJBUUNyWGhzZHk4aW5V
	|ckFSXG4zNjkvVk9wckhFWjBuQ1VCUXFrb2lyOEFsY1pWYzdVa2lRaDFpL29lSGE5
	|M1hOQXp4eWViQUU4TTF6ZTRYMWR0XG54RVMyamlqdVBTalRjTUE3Wm12R2ovS3ZU
	|Y0g4aDVqY2JWdzhwUzhXN0dmZXNCdHJ3M0R1RGNnZ3lUWW5BVGZyXG5OajFhanFD
	|UkJnYlNHVnRaSEhwdGNhMnprOUV5YlZMbHl1Rkc4dXhONHV2eWNGQlhpZUFVdmJ2
	|cHdHS2xLM2RHXG50MEZjcS9DS3MwVmR3WDFKKzFQVmlRYTBGcDVpMUpZSk9Bc1lO
	|RnJxVFhObjBaWGY1aVNBc1F2c2srOEI1RGtJXG5PUktoRU0rNXFPeXNwcndRallN
	|anYyOE1YWC9sVXZtRmZnWUtIK1Z2enpEa2ZSengyWEtBeVFEWStEOVplblM2XG5w
	|Y2NHd1BDSkFnTUJBQUVDZ2dFQVFUYXl3d2dGK0FiemtobTV3NDhoRmxuUVJoZ1Z6
	|UUQ5TnJ4MksxYlQvempsXG5PbDRicGYvNjB2TWhEeDkyNi8xaUNRNTVCcjN3S20y
	|OTY3dkJHbWZIRThLYWdyeHBxekV5Mm9GMUxWazk5VWYwXG4yQTJXQ0U0a09Xa0Zy
	|aXorZ21nQjFkWFF6d2xEWGx5TVZ5cHc5c0ZJUVdnMXVFYUdDTWRabjhTZkFiUEM3
	|SmttXG5nSktBTlRpZ3lsUkl0aW1UYUg4V2tPbktnNWRKdkF1N0tlZ0xQczhuWlJI
	|RVFINnJjYXB4L3FkNmVMMWtPQkQ3XG5oSkVjbXBEMnlZWlJERUVIUm5PMUloeTZ0
	|K3ZVeG5QMW5JRkllN1RCK3Q3bndxOVljSWNta240RytUQ2FvV3dLXG5GRG5ZN3pz
	|aTJhNFBqdXpNeHpTK2xTZEFiUTFHMFJVUld5K2ZnZ21sc1FLQmdRRFVZRWVROW9H
	|dnZianFRcTZpXG5NeXNCN2tGcGp4UHZjNllBY2k1Q1ZWcm00Z2IzeWd5aGZpWHNI
	|Y2ZOQmRhc2c5elpYTk5WdW9aWmxNV3R1YXF5XG55NzEvRG5oYlcvcTdES09FbGwy
	|REQ2dUFhektTdFpPR2xkWWJ0VHBjbU5nUkhTcUZDVFlLZmY1SXVRenhva0Q4XG5U
	|MXhQQndPcjAxVFNFM3dnTFM5eVBpK1BFd0tCZ1FET2tXamRNRjMxbit0bTgrNXEv
	|WFpuYUxXYXIyWmo5N0lrXG4zRTJub0hDMldVdUR0Y0ZNeVMrOHg2RWJJWUNrcW51
	|S0NFYWtQM0hNcStmOHJCNWtpcW9HcDNTTFpuSTdNN0g4XG5GazczV3BIaHpxTlRG
	|NCsvbWdIYU51dWZDeklnZG1JUXRlTVhBU1c4MnJkNklHWWlKMkV6VGdaUHcyOCtK
	|N0dHXG5tYkFJSnJRSmN3S0JnRVRDNDRrQTl4NVNmQ09FOFl2Y3Ewa1Z2aUlTVEM4
	|VUw2UW5VK2p3UDkxUFExaEpGK3ZWXG5yeXVTdk5VWjFkYkhYdU1WbGV0RTJDajY3
	|VUlCUWs1ZmZ2dzdVQ2FzVWpMcnRhbkJFWWZVcy8rQk5iK2dnS0pyXG5zd1lIbUZ6
	|UXMreGVtQnk0emNGNTU3SGVFRjNQM2VDVFJWems5WUJWalRuelN4WVQ2eSsvQ0tE
	|M0FvR0FBbEt1XG5URFo4Q0FRWllKb0RwMTVjVTROZzczRmpoR0pIdFpSb3B5YnR2
	|WTg1Z3l5ckZOTDZYM1FiUXJQWXY0RlBURmtWXG5la2xnWFQzZHFRRENncnp3ZG95
	|eGlkUElHeFJVdnhIOUoxajBaUWF1M1lOWlVYMUk0Z3hXRC83UFBJQTRVQm5MXG5p
	|UG14VS9OZHR0amdiU2ZtTnU1OHNhN3Y5Rkg3OUJpTVd6c2NNVE1DZ1lBWWliemFm
	|cTZUb3VveEM4YVFITUNxXG54MEFTY2VmWHZxcTk3K0szZkl1TENHT1NhL1BtTVd5
	|RTBHa1V6UkFRNmsyNFE0YmwzbFc0amxmVkNsQm9Wcm1nXG5VNEtTN2VIWWFTMk40
	|UjFOVjRSK24zeDNnVzM5RVVIVHNnZ3lDZUZITUo3M0tOb1p3TTFaMEhMTEhTZm5B
	|SE9SXG54MmRCREpsbVB0SjI5c3BpS0QrTUlBPT1cbi0tLS0tRU5EIFBSSVZBVEUg
	|S0VZLS0tLS1cbiIsCiAgImNsaWVudF9lbWFpbCI6ICJiZnNlbmRtZXNzYWdlc0Bi
	|aXRmaW5hbmNlLWdyb3RlbS5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsCiAgImNs
	|aWVudF9pZCI6ICIxMDk5MDY3MDk3MDUxMTk2NDEzNzgiLAogICJhdXRoX3VyaSI6
	|ICJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20vby9vYXV0aDIvYXV0aCIsCiAg
	|InRva2VuX3VyaSI6ICJodHRwczovL29hdXRoMi5nb29nbGVhcGlzLmNvbS90b2tl
	|biIsCiAgImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3d3
	|dy5nb29nbGVhcGlzLmNvbS9vYXV0aDIvdjEvY2VydHMiLAogICJjbGllbnRfeDUw
	|OV9jZXJ0X3VybCI6ICJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9yb2JvdC92
	|MS9tZXRhZGF0YS94NTA5L2Jmc2VuZG1lc3NhZ2VzJTQwYml0ZmluYW5jZS1ncm90
	|ZW0uaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLAogICJ1bml2ZXJzZV9kb21haW4i
	|OiAiZ29vZ2xlYXBpcy5jb20iCn0=";
	ДвоичныеДанныеСтроки = Base64Значение(ОписаниеКлюча);
	ОписаниеКлюча = ПолучитьСтрокуИзДвоичныхДанных(ДвоичныеДанныеСтроки);	

	ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(ОписаниеКлюча);
	ДанныеКлюча = ПрочитатьJSON(ЧтениеJSON);
	ЧтениеJSON.Закрыть();
	
	ВремяСоздания =  ТекущаяУниверсальнаяДата() - Дата(1970,1,1,0,0,0);
	ВремяОкончания = ВремяСоздания + 3600;
	
	ТокенДоступа = Новый ТокенДоступа();
	ТокенДоступа.Эмитент = ДанныеКлюча.client_email;
	ТокенДоступа.Получатели.Добавить(ДанныеКлюча.token_uri);
	ТокенДоступа.ВремяСоздания = ВремяСоздания;
	ТокенДоступа.ВремяЖизни = 3600;
	ТокенДоступа.ПолезнаяНагрузка.Вставить("scope", "https://www.googleapis.com/auth/firebase.messaging");
	
	// Подписание.
    ТокенДоступа.Подписать(АлгоритмПодписиТокенаДоступа.RS256, ДанныеКлюча.private_key);
    
    Возврат ТокенДоступа;
    
КонецФункции

#КонецОбласти

#Иначе
  ВызватьИсключение НСтр("ru='Недопустимый вызов объекта на клиенте.';en='Invalid object call on client'");
#КонецЕсли