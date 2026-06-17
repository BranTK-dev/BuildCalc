#pragma once

#include <QObject>
#include <QSettings>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class CalculatorEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap recent READ recent NOTIFY recentChanged)
    Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
    Q_PROPERTY(QString country READ country NOTIFY countryChanged)
    Q_PROPERTY(QString currencyCode READ currencyCode NOTIFY countryChanged)
    Q_PROPERTY(QString currencySymbol READ currencySymbol NOTIFY countryChanged)
    Q_PROPERTY(bool darkTheme READ darkTheme NOTIFY darkThemeChanged)

public:
    explicit CalculatorEngine(QObject *parent = nullptr);

    QVariantMap recent() const;
    QVariantList history() const;
    QString country() const;
    QString currencyCode() const;
    QString currencySymbol() const;
    bool darkTheme() const;

    Q_INVOKABLE QVariantMap calculate(const QString &calculator, const QVariantMap &inputs);
    Q_INVOKABLE QString shareText(const QVariantMap &result) const;
    Q_INVOKABLE void copyText(const QString &text) const;
    Q_INVOKABLE QVariantList countries() const;
    Q_INVOKABLE void setCountry(const QString &country);
    Q_INVOKABLE void setDarkTheme(bool enabled);
    Q_INVOKABLE void clearRecent();
    Q_INVOKABLE void clearHistory();

signals:
    void recentChanged();
    void historyChanged();
    void countryChanged();
    void darkThemeChanged();

private:
    QVariantMap calculatePaint(const QVariantMap &inputs) const;
    QVariantMap calculateTiling(const QVariantMap &inputs) const;
    QVariantMap calculateFlooring(const QVariantMap &inputs) const;
    QVariantMap calculateConcrete(const QVariantMap &inputs) const;
    QVariantMap calculateBricks(const QVariantMap &inputs) const;
    QVariantMap calculatePlastering(const QVariantMap &inputs) const;
    QVariantMap calculateRoofing(const QVariantMap &inputs) const;

    QVariantMap errorResult(const QString &message) const;
    void saveRecent(const QVariantMap &result);
    void saveHistory(const QVariantMap &result);

    static double number(const QVariantMap &inputs, const QString &key, double fallback = 0.0);
    static int integer(const QVariantMap &inputs, const QString &key, int fallback = 0);
    static QString money(double value, const QVariantMap &inputs);
    static QString formatShareText(const QVariantMap &result);

    QSettings m_settings;
};
