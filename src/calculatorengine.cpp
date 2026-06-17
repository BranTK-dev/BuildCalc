#include "calculatorengine.h"

#include <QDateTime>
#include <QGuiApplication>
#include <QLocale>
#include <QClipboard>
#include <QtMath>

namespace {
constexpr double PaintCoverageM2PerLiter = 10.0;
constexpr double PaintWasteFactor = 1.10;
constexpr double TileWasteFactor = 1.10;
constexpr double FlooringWasteFactor = 1.10;
constexpr double BrickWasteFactor = 1.05;
constexpr double DryConcreteFactor = 1.54;
constexpr double CementBagVolumeM3 = 0.0347;
constexpr int MaxHistoryItems = 25;

struct CurrencyInfo {
    const char *country;
    const char *iso2;
    const char *initials;
    const char *code;
    const char *symbol;
};

constexpr CurrencyInfo CurrencyTable[] = {
    {"South Africa", "ZA", "ZA", "ZAR", "R"},
    {"United States", "US", "US", "USD", "$"},
    {"United Kingdom", "GB", "UK", "GBP", "GBP"},
    {"European Union", "EU", "EU", "EUR", "EUR"},
    {"Canada", "CA", "CA", "CAD", "C$"},
    {"Australia", "AU", "AU", "AUD", "A$"},
    {"New Zealand", "NZ", "NZ", "NZD", "NZ$"},
    {"Nigeria", "NG", "NG", "NGN", "NGN"},
    {"Kenya", "KE", "KE", "KES", "KSh"},
    {"Ghana", "GH", "GH", "GHS", "GHS"},
    {"India", "IN", "IN", "INR", "INR"},
    {"Brazil", "BR", "BR", "BRL", "R$"},
    {"Mexico", "MX", "MX", "MXN", "MX$"},
    {"Japan", "JP", "JP", "JPY", "JPY"},
    {"China", "CN", "CN", "CNY", "CNY"},
};

double roundTo(double value, int places)
{
    const double factor = qPow(10.0, places);
    return qRound64(value * factor) / factor;
}

QString compactNumber(double value, int places = 1)
{
    QString text = QString::number(roundTo(value, places), 'f', places);
    while (text.contains('.') && text.endsWith('0')) {
        text.chop(1);
    }
    if (text.endsWith('.')) {
        text.chop(1);
    }
    return text;
}

CurrencyInfo currencyForCountry(const QString &country)
{
    for (const CurrencyInfo &info : CurrencyTable) {
        if (country == QString::fromUtf8(info.country)) {
            return info;
        }
    }
    return CurrencyTable[0];
}

CurrencyInfo currencyForIso2(const QString &iso2)
{
    for (const CurrencyInfo &info : CurrencyTable) {
        if (iso2.compare(QString::fromUtf8(info.iso2), Qt::CaseInsensitive) == 0) {
            return info;
        }
    }
    if (iso2.compare(QStringLiteral("DE"), Qt::CaseInsensitive) == 0
        || iso2.compare(QStringLiteral("FR"), Qt::CaseInsensitive) == 0
        || iso2.compare(QStringLiteral("IT"), Qt::CaseInsensitive) == 0
        || iso2.compare(QStringLiteral("ES"), Qt::CaseInsensitive) == 0
        || iso2.compare(QStringLiteral("NL"), Qt::CaseInsensitive) == 0
        || iso2.compare(QStringLiteral("IE"), Qt::CaseInsensitive) == 0
        || iso2.compare(QStringLiteral("PT"), Qt::CaseInsensitive) == 0) {
        return currencyForCountry(QStringLiteral("European Union"));
    }
    return CurrencyTable[0];
}

QString detectedCountry()
{
    const QString localeName = QLocale::system().name();
    const int separator = localeName.indexOf('_');
    if (separator < 0 || separator + 1 >= localeName.size()) {
        return QString::fromUtf8(CurrencyTable[0].country);
    }
    return QString::fromUtf8(currencyForIso2(localeName.mid(separator + 1)).country);
}
}

CalculatorEngine::CalculatorEngine(QObject *parent)
    : QObject(parent)
    , m_settings("BuildCalc", "BuildCalc")
{
}

QVariantMap CalculatorEngine::recent() const
{
    return m_settings.value("recent").toMap();
}

QVariantList CalculatorEngine::history() const
{
    return m_settings.value("history").toList();
}

QString CalculatorEngine::country() const
{
    return m_settings.value("country", detectedCountry()).toString();
}

QString CalculatorEngine::currencyCode() const
{
    return QString::fromUtf8(currencyForCountry(country()).code);
}

QString CalculatorEngine::currencySymbol() const
{
    return QString::fromUtf8(currencyForCountry(country()).symbol);
}

bool CalculatorEngine::darkTheme() const
{
    return m_settings.value("darkTheme", false).toBool();
}

QVariantMap CalculatorEngine::calculate(const QString &calculator, const QVariantMap &inputs)
{
    QVariantMap result;

    if (calculator == "paint") {
        result = calculatePaint(inputs);
    } else if (calculator == "tiling") {
        result = calculateTiling(inputs);
    } else if (calculator == "flooring") {
        result = calculateFlooring(inputs);
    } else if (calculator == "concrete") {
        result = calculateConcrete(inputs);
    } else if (calculator == "bricks") {
        result = calculateBricks(inputs);
    } else if (calculator == "plastering") {
        result = calculatePlastering(inputs);
    } else if (calculator == "roofing") {
        result = calculateRoofing(inputs);
    } else {
        result = errorResult("Choose a calculator first.");
    }

    if (result.value("ok").toBool()) {
        saveRecent(result);
        saveHistory(result);
    }

    return result;
}

QString CalculatorEngine::shareText(const QVariantMap &result) const
{
    return formatShareText(result);
}

void CalculatorEngine::copyText(const QString &text) const
{
    if (QClipboard *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(text);
    }
}

QVariantList CalculatorEngine::countries() const
{
    QVariantList list;
    for (const CurrencyInfo &info : CurrencyTable) {
        QVariantMap item;
        item["country"] = QString::fromUtf8(info.country);
        item["initials"] = QString::fromUtf8(info.initials);
        item["currencyCode"] = QString::fromUtf8(info.code);
        item["currencySymbol"] = QString::fromUtf8(info.symbol);
        item["shortLabel"] = QString("%1 %2").arg(QString::fromUtf8(info.initials), QString::fromUtf8(info.code));
        item["label"] = QString("%1 (%2)").arg(QString::fromUtf8(info.country), QString::fromUtf8(info.code));
        list.append(item);
    }
    return list;
}

void CalculatorEngine::setCountry(const QString &country)
{
    const CurrencyInfo info = currencyForCountry(country);
    const QString normalizedCountry = QString::fromUtf8(info.country);
    if (this->country() == normalizedCountry) {
        return;
    }
    m_settings.setValue("country", normalizedCountry);
    emit countryChanged();
}

void CalculatorEngine::setDarkTheme(bool enabled)
{
    if (darkTheme() == enabled) {
        return;
    }
    m_settings.setValue("darkTheme", enabled);
    emit darkThemeChanged();
}

void CalculatorEngine::clearRecent()
{
    m_settings.remove("recent");
    emit recentChanged();
}

void CalculatorEngine::clearHistory()
{
    m_settings.remove("history");
    emit historyChanged();
}

QVariantMap CalculatorEngine::calculatePaint(const QVariantMap &inputs) const
{
    const double width = number(inputs, "width");
    const double height = number(inputs, "height");
    const int coats = integer(inputs, "coats", 2);
    const double price = number(inputs, "price");

    if (width <= 0 || height <= 0 || coats <= 0) {
        return errorResult("Enter wall width, height, and coats.");
    }

    const double area = width * height;
    const double liters = area * coats / PaintCoverageM2PerLiter * PaintWasteFactor;
    const int cans = qCeil(liters / 5.0);

    QVariantMap result;
    result["ok"] = true;
    result["calculator"] = "paint";
    result["title"] = "Paint calculator";
    result["headline"] = QString("%1 x 5L cans").arg(cans);
    result["context"] = QString("Approx. %1 liters for %2 m² wall, %3 coat%4")
                            .arg(compactNumber(liters, 1))
                            .arg(compactNumber(area, 1))
                            .arg(coats)
                            .arg(coats == 1 ? "" : "s");
    result["purchase"] = QString("5L cans needed: %1").arg(cans);
    result["secondary"] = QString("Includes 10% extra for touch-ups and waste.");
    result["cost"] = price > 0 ? money(cans * price, inputs) : QString();
    result["currencyCode"] = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return result;
}

QVariantMap CalculatorEngine::calculateTiling(const QVariantMap &inputs) const
{
    const double width = number(inputs, "width");
    const double height = number(inputs, "height");
    const double tileWidth = number(inputs, "tileWidth", 0.3);
    const double tileHeight = number(inputs, "tileHeight", 0.3);
    const double price = number(inputs, "price");

    if (width <= 0 || height <= 0 || tileWidth <= 0 || tileHeight <= 0) {
        return errorResult("Enter the surface and tile sizes.");
    }

    const double area = width * height;
    const double buyArea = area * TileWasteFactor;
    const int tiles = qCeil(buyArea / (tileWidth * tileHeight));

    QVariantMap result;
    result["ok"] = true;
    result["calculator"] = "tiling";
    result["title"] = "Tiling calculator";
    result["headline"] = QString("%1 tiles").arg(tiles);
    result["context"] = QString("Covers %1 m², including 10% spare").arg(compactNumber(buyArea, 1));
    result["purchase"] = QString("Tiles to buy: %1").arg(tiles);
    result["secondary"] = QString("Covers %1 m², based on %2 m x %3 m tiles.")
                              .arg(compactNumber(buyArea, 1))
                              .arg(compactNumber(tileWidth, 2))
                              .arg(compactNumber(tileHeight, 2));
    result["cost"] = price > 0 ? money(tiles * price, inputs) : QString();
    result["currencyCode"] = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return result;
}

QVariantMap CalculatorEngine::calculateFlooring(const QVariantMap &inputs) const
{
    const double width = number(inputs, "width");
    const double length = number(inputs, "length");
    const double packCoverage = number(inputs, "packCoverage", 2.2);
    const double price = number(inputs, "price");

    if (width <= 0 || length <= 0 || packCoverage <= 0) {
        return errorResult("Enter room size and pack coverage.");
    }

    const double area = width * length;
    const double buyArea = area * FlooringWasteFactor;
    const int packs = qCeil(buyArea / packCoverage);

    QVariantMap result;
    result["ok"] = true;
    result["calculator"] = "flooring";
    result["title"] = "Flooring calculator";
    result["headline"] = QString("%1 packs").arg(packs);
    result["context"] = QString("Covers %1 m² floor, including 10% spare").arg(compactNumber(buyArea, 1));
    result["purchase"] = QString("Flooring to buy: %1 m²").arg(compactNumber(buyArea, 1));
    result["secondary"] = QString("Pack coverage: %1 m² each.").arg(compactNumber(packCoverage, 1));
    result["cost"] = price > 0 ? money(packs * price, inputs) : QString();
    result["currencyCode"] = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return result;
}

QVariantMap CalculatorEngine::calculateConcrete(const QVariantMap &inputs) const
{
    const double length = number(inputs, "length");
    const double width = number(inputs, "width");
    const double depth = number(inputs, "depth");
    const double price = number(inputs, "price");
    const double sandPrice = number(inputs, "price2");
    const double stonePrice = number(inputs, "price3");

    if (length <= 0 || width <= 0 || depth <= 0) {
        return errorResult("Enter length, width, and depth.");
    }

    const double wetVolume = length * width * depth;
    const double dryVolume = wetVolume * DryConcreteFactor;
    const int cementBags = qCeil((dryVolume / 7.0) / CementBagVolumeM3);
    const double sand = dryVolume * 2.0 / 7.0;
    const double stone = dryVolume * 4.0 / 7.0;

    QVariantMap result;
    result["ok"] = true;
    result["calculator"] = "concrete";
    result["title"] = "Concrete calculator";
    result["headline"] = QString("%1 m³ concrete").arg(compactNumber(wetVolume, 2));
    result["context"] = QString("For a %1 m x %2 m x %3 m slab").arg(compactNumber(length, 1), compactNumber(width, 1), compactNumber(depth, 2));
    result["purchase"] = QString("50kg cement bags: %1").arg(cementBags);
    result["secondary"] = QString("Approx. sand: %1 m³, stone: %2 m³.").arg(compactNumber(sand, 2), compactNumber(stone, 2));
    const double totalCost = (cementBags * price) + (sand * sandPrice) + (stone * stonePrice);
    result["cost"] = totalCost > 0 ? money(totalCost, inputs) : QString();
    result["currencyCode"] = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return result;
}

QVariantMap CalculatorEngine::calculateBricks(const QVariantMap &inputs) const
{
    const double length = number(inputs, "length");
    const double height = number(inputs, "height");
    const double price = number(inputs, "price");

    if (length <= 0 || height <= 0) {
        return errorResult("Enter wall length and height.");
    }

    const double area = length * height;
    const int bricks = qCeil(area * 50.0 * BrickWasteFactor);

    QVariantMap result;
    result["ok"] = true;
    result["calculator"] = "bricks";
    result["title"] = "Brick calculator";
    result["headline"] = QString("%1 bricks").arg(bricks);
    result["context"] = QString("For %1 m² single-skin wall").arg(compactNumber(area, 1));
    result["purchase"] = QString("Bricks to buy: %1").arg(bricks);
    result["secondary"] = QString("Uses 50 bricks per m² plus 5% extra.");
    result["cost"] = price > 0 ? money(bricks * price, inputs) : QString();
    result["currencyCode"] = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return result;
}

QVariantMap CalculatorEngine::calculatePlastering(const QVariantMap &inputs) const
{
    const double width = number(inputs, "width");
    const double height = number(inputs, "height");
    const double thicknessMm = number(inputs, "thickness", 12.0);
    const double price = number(inputs, "price");
    const double sandPrice = number(inputs, "price2");

    if (width <= 0 || height <= 0 || thicknessMm <= 0) {
        return errorResult("Enter wall size and plaster thickness.");
    }

    const double area = width * height;
    const double wetVolume = area * (thicknessMm / 1000.0);
    const double dryVolume = wetVolume * 1.30;
    const int cementBags = qCeil((dryVolume / 5.0) / CementBagVolumeM3);
    const double sand = dryVolume * 4.0 / 5.0;

    QVariantMap result;
    result["ok"] = true;
    result["calculator"] = "plastering";
    result["title"] = "Plastering calculator";
    result["headline"] = QString("%1 cement bags").arg(cementBags);
    result["context"] = QString("Covers %1 m² at %2 mm thick").arg(compactNumber(area, 1), compactNumber(thicknessMm, 0));
    result["purchase"] = QString("50kg cement bags: %1").arg(cementBags);
    result["secondary"] = QString("Approx. plaster sand: %1 m³.").arg(compactNumber(sand, 2));
    const double totalCost = (cementBags * price) + (sand * sandPrice);
    result["cost"] = totalCost > 0 ? money(totalCost, inputs) : QString();
    result["currencyCode"] = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return result;
}

QVariantMap CalculatorEngine::calculateRoofing(const QVariantMap &inputs) const
{
    const double roofWidth = number(inputs, "width");
    const double slopeLength = number(inputs, "length");
    const double coverWidth = number(inputs, "coverWidth", 0.762);
    const double price = number(inputs, "price");

    if (roofWidth <= 0 || slopeLength <= 0 || coverWidth <= 0) {
        return errorResult("Enter roof width, sheet length, and cover width.");
    }

    const int sheets = qCeil(roofWidth / coverWidth);
    const double roofArea = roofWidth * slopeLength;

    QVariantMap result;
    result["ok"] = true;
    result["calculator"] = "roofing";
    result["title"] = "Roofing sheet calculator";
    result["headline"] = QString("%1 sheets").arg(sheets);
    result["context"] = QString("Covers about %1 m² roof area").arg(compactNumber(roofArea, 1));
    result["purchase"] = QString("Sheet length: %1 m each").arg(compactNumber(slopeLength, 1));
    result["secondary"] = QString("Effective cover width: %1 m.").arg(compactNumber(coverWidth, 3));
    result["cost"] = price > 0 ? money(sheets * price, inputs) : QString();
    result["currencyCode"] = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return result;
}

QVariantMap CalculatorEngine::errorResult(const QString &message) const
{
    QVariantMap result;
    result["ok"] = false;
    result["error"] = message;
    return result;
}

void CalculatorEngine::saveRecent(const QVariantMap &result)
{
    QVariantMap recentResult;
    recentResult["calculator"] = result.value("calculator");
    recentResult["title"] = result.value("title");
    recentResult["headline"] = result.value("headline");
    recentResult["context"] = result.value("context");

    m_settings.setValue("recent", recentResult);
    emit recentChanged();
}

void CalculatorEngine::saveHistory(const QVariantMap &result)
{
    QVariantMap item;
    item["calculator"] = result.value("calculator");
    item["title"] = result.value("title");
    item["headline"] = result.value("headline");
    item["context"] = result.value("context");
    item["purchase"] = result.value("purchase");
    item["secondary"] = result.value("secondary");
    item["cost"] = result.value("cost");
    item["currencyCode"] = result.value("currencyCode");
    item["timestamp"] = QDateTime::currentDateTime().toString(QStringLiteral("dd MMM yyyy, HH:mm"));
    item["shareText"] = formatShareText(item);

    QVariantList items = history();
    items.prepend(item);
    while (items.size() > MaxHistoryItems) {
        items.removeLast();
    }

    m_settings.setValue("history", items);
    emit historyChanged();
}

double CalculatorEngine::number(const QVariantMap &inputs, const QString &key, double fallback)
{
    bool ok = false;
    const double value = inputs.value(key, fallback).toDouble(&ok);
    return ok ? value : fallback;
}

int CalculatorEngine::integer(const QVariantMap &inputs, const QString &key, int fallback)
{
    bool ok = false;
    const int value = inputs.value(key, fallback).toInt(&ok);
    return ok ? value : fallback;
}

QString CalculatorEngine::money(double value, const QVariantMap &inputs)
{
    const QString symbol = inputs.value("currencySymbol", QStringLiteral("R")).toString();
    const QString code = inputs.value("currencyCode", QStringLiteral("ZAR")).toString();
    return QString("Estimated cost: %1 %2 (%3)").arg(symbol, QString::number(roundTo(value, 2), 'f', 2), code);
}

QString CalculatorEngine::formatShareText(const QVariantMap &result)
{
    QStringList lines;
    lines << QStringLiteral("BuildCalc Material Estimate");
    lines << QStringLiteral("");
    lines << QStringLiteral("Hello,");
    lines << QStringLiteral("");
    lines << QStringLiteral("Please find the material estimate summary below:");
    lines << QStringLiteral("");
    lines << QString("Calculator: %1").arg(result.value("title").toString());
    lines << QString("Estimated quantity: %1").arg(result.value("headline").toString());
    lines << QString("Project basis: %1").arg(result.value("context").toString());
    lines << QString("Recommended purchase: %1").arg(result.value("purchase").toString());

    const QString secondary = result.value("secondary").toString();
    if (!secondary.isEmpty()) {
        lines << QString("Notes: %1").arg(secondary);
    }

    const QString cost = result.value("cost").toString();
    if (!cost.isEmpty()) {
        lines << QString("Estimated material cost: %1").arg(cost.mid(QStringLiteral("Estimated cost: ").size()));
    } else {
        lines << QStringLiteral("Estimated material cost: Not included");
    }

    const QString timestamp = result.value("timestamp").toString();
    if (!timestamp.isEmpty()) {
        lines << QString("Estimate date: %1").arg(timestamp);
    }

    lines << QStringLiteral("");
    lines << QStringLiteral("This estimate is intended for planning purposes. Please confirm final measurements, product coverage, pack sizes, and supplier pricing before purchasing materials.");
    lines << QStringLiteral("");
    lines << QStringLiteral("Prepared with BuildCalc.");
    return lines.join('\n');
}
