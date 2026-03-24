
#Область СлужебныйПрограммныйИнтерфейс

// Создает объект PowerPoint.
// 
// Параметры:
//  Нет.
// 
// Возвращаемое значение:
//   ComObject, Неопределено.
// 
Функция InitPowerPoint() Экспорт
	
	PowerPointApp = Неопределено;
	
	#Если Не МобильныйКлиент Тогда
	Попытка
		// Создание объекта Microsoft PowerPoint.
		PowerPointApp = Новый COMОбъект("PowerPoint.Application");
		PowerPointApp.DisplayAlerts = Ложь;
		PowerPointApp.Visible       = Истина;
	Исключение
		PowerPointApp = Неопределено;
		ТекстСообщения = НСтр("ru='Не удалось создать объект PowerPoint по причине: %1.';
							  |en='Failed to create a PowerPoint object, reason: %1.'");
		ТекстСообщения = СтрШаблон(ТекстСообщения, ОбработкаОшибок.КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
		бит_ОбщегоНазначенияКлиентСервер.ВывестиСообщение(ТекстСообщения);
	КонецПопытки;
	#КонецЕсли
	
	Возврат PowerPointApp;
	
КонецФункции

// Процедура закрывает PowerPoint.
// 
// Параметры:
//  PowerPointApp - ComObject.
// 
Процедура QuitPowerPoint(PowerPointApp) Экспорт
	
	Если PowerPointApp <> Неопределено Тогда
		PowerPointApp.Quit();
		PowerPointApp = Неопределено;
	КонецЕсли;
	
КонецПроцедуры

// Функция открывает PowerPoint файл.
// 
// Параметры:
//  PowerPoint - ComObject("PowerPoint.Application").
//  ПутьКФайлу - Строка, полный путь где лежит файл.
// 
// Возвращаемое значение:
//   ComObject, Неопределено.
// 
Функция OpenPowerPointFile(PowerPointApp, ПутьКФайлу) Экспорт
	
	PowerPointFile = Неопределено;		
	
	Если PowerPointApp <> Неопределено Тогда
		Попытка
			PowerPointFile = PowerPointApp.Presentations.Open(ПутьКФайлу);
		Исключение
			PowerPointFile = Неопределено;
			ТекстСообщения = НСтр("ru='Не удалось открыть PowerPoint файл ""%1"" по причине: %2';
								  |en='Unable to open the PowerPoint file ""%1"" for a reason: %2'");
			ТекстСообщения = СтрШаблон(ТекстСообщения, ПутьКФайлу, ОбработкаОшибок.КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
			бит_ОбщегоНазначенияКлиентСервер.ВывестиСообщение(ТекстСообщения);
		КонецПопытки;
	КонецЕсли;
	
	Возврат PowerPointFile;
	
КонецФункции

#КонецОбласти
