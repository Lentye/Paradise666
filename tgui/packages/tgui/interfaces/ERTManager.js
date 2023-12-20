import { useBackend, useLocalState } from "../backend";
import { Button, LabeledList, Box, Section, Tabs } from "../components";
import { Window } from "../layouts";

export const ERTManager = (props, context) => {
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 0);
  const decideTab = index => {
    switch (index) {
      case 0:
        return <SquadManager />;
      case 1:
        return <Information />;
    }
  };

  return (
    <Window>
      <Window.Content scrollable>
        <Box fillPositionedParent>
          <Tabs>
            <Tabs.Tab
              key="ERT"
              selected={0 === tabIndex}
              onClick={() => setTabIndex(0)}
              icon="ambulance"
              content="ERT" />
            <Tabs.Tab>
            <Tabs.Tab
              key="Information"
              selected={1 === tabIndex}
              onClick={() => setTabIndex(1)}
              icon="info-circle"
              content="Information" />
            </Tabs.Tab>
          </Tabs>
          {decideTab(tabIndex)}
        </Box>
      </Window.Content>
    </Window>
  );
};

const SquadManager = (props, context) => {
  const { act, data } = useBackend(context);
  let slotOptions = [0, 1, 2, 3, 4, 5];

  return (
      <Box>
        <Section title="Overview">
          <LabeledList>
            <LabeledList.Item label="Current Alert"
              color={data.security_level_color}>
              {data.str_security_level}
            </LabeledList.Item>
            <LabeledList.Item label="ERT Type">
              <Button
                content="Amber"
                color={data.ert_type === "Amber"
                  ? "orange"
                  : ""}
                onClick={() => act('ert_type', { ert_type: "Amber" })} />
              <Button
                content="Red"
                color={data.ert_type === "Red"
                  ? "red"
                  : ""}
                onClick={() => act('ert_type', { ert_type: "Red" })} />
              <Button
                content="Gamma"
                color={data.ert_type === "Gamma"
                  ? "purple"
                  : ""}
                onClick={() => act('ert_type', { ert_type: "Gamma" })} />
            </LabeledList.Item>
            <LabeledList.Item label="Manual Сheck">
              <Button
                key={"manual_check"}
                selected={data.manual_check !== data.manual_check}
                content={'Allow manual selection?'}
                onClick={() => act('manual_check')}
                color={data.manual_check === 1
                  ? "green"
                  : ""}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Prevent Announce">
              <Button
                  key={"prevent_announce"}
                  selected={data.manual_check !== data.manual_check}
                  content={'Prevent announce?'}
                  onClick={() => act('prevent_announce')}
                   color={data.prevent_announce === 1
                    ? "red"
                    : ""}
               />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Slots">
          <LabeledList>
            <LabeledList.Item label="Commander">
              <Button
                content={data.com > 0 ? "Yes" : "No"}
                selected={data.com > 0}
                onClick={() => act('toggle_com')} />
            </LabeledList.Item>
            <LabeledList.Item label="Security">
              {slotOptions.map((a, i) => (
                <Button
                  key={"sec" + a}
                  selected={data.sec === a}
                  content={a}
                  onClick={() => act('set_sec', {
                    set_sec: a,
                  })}
                />
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Medical">
              {slotOptions.map((a, i) => (
                <Button
                  key={"med" + a}
                  selected={data.med === a}
                  content={a}
                  onClick={() => act('set_med', {
                    set_med: a,
                  })}
                />
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Engineering">
              {slotOptions.map((a, i) => (
                <Button
                  key={"eng" + a}
                  selected={data.eng === a}
                  content={a}
                  onClick={() => act('set_eng', {
                    set_eng: a,
                  })}
                />
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Paranormal">
              {slotOptions.map((a, i) => (
                <Button
                  key={"par" + a}
                  selected={data.par === a}
                  content={a}
                  onClick={() => act('set_par', {
                    set_par: a,
                  })}
                />
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Janitor">
              {slotOptions.map((a, i) => (
                <Button
                  key={"jan" + a}
                  selected={data.jan === a}
                  content={a}
                  onClick={() => act('set_jan', {
                    set_jan: a,
                  })}
                />
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Cyborg">
              {slotOptions.map((a, i) => (
                <Button
                  key={"cyb" + a}
                  selected={data.cyb === a}
                  content={a}
                  onClick={() => act('set_cyb', {
                    set_cyb: a,
                  })}
                />
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Total Slots">
              <Box color={data.total > data.spawnpoints
                ? "red"
                : "green"}>
                {data.total} total, versus {data.spawnpoints} spawnpoints
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Dispatch">
              <Button
                icon="ambulance"
                content="Send ERT"
                onClick={() => act('dispatch_ert')} />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Box>
  );
};

const Information = (props, context) => {
  const { act, data } = useBackend(context);

  return(
  <Box >
    <Section title="Manual Selection">
      <Box >
        Возможность отобрать игроков группы в ручную, если количество добровольцев больше количества слотов(иначе разницы нет)
      </Box>
    </Section>
    <Section title="Prevent Announce">
    <Box >
      Возможность отключить автоматическое оповещение о сборе и отправке отряда ; повышает шанс отсутствия ловушки у порта прибытия и подготовки к противостоянию с ОБР
    </Box>
    </Section>
  </Box>
  );
};
